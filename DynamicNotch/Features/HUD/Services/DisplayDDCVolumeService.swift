import CoreGraphics
import Foundation
import IOKit

/// Serialized off the main actor: monitor I2C transactions can take tens of ms.
/// IOAVService is an optional private IOKit interface, also used by m1ddc:
/// https://github.com/waydabber/m1ddc (MIT). No external helper is installed.
actor DisplayDDCVolumeService: DisplayVolumeControlling {
    private let api = DDCIOKitAPI()

    func readVolume(displayID: UInt32) -> DisplayDDCVolume? {
        guard let endpoint = endpoint(for: displayID) else { return nil }
        return read(endpoint, displayID: displayID)
    }

    func setVolume(_ fraction: Double, displayID: UInt32) -> DisplayDDCVolume? {
        guard fraction.isFinite, let endpoint = endpoint(for: displayID),
              let previous = read(endpoint, displayID: displayID) else { return nil }
        let value = UInt16((max(0, min(1, fraction)) * Double(previous.maximum)).rounded())
        guard write(DisplayDDCProtocol.writeRequest(value), to: endpoint) else { return nil }
        // Report the monitor's value, not merely a successful I2C send.
        return read(endpoint, displayID: displayID)
    }

    private struct Endpoint {
        let service: CFTypeRef
        let chip: UInt32
    }

    private func read(_ endpoint: Endpoint, displayID: UInt32) -> DisplayDDCVolume? {
        guard let api else { return nil }
        for _ in 0..<3 {
            guard write(DisplayDDCProtocol.readRequest(), to: endpoint) else { continue }
            Thread.sleep(forTimeInterval: 0.05)
            var bytes = [UInt8](repeating: 0, count: 12)
            let status = bytes.withUnsafeMutableBytes {
                api.read(endpoint.service, endpoint.chip, 0x51, $0.baseAddress, UInt32($0.count))
            }
            if status == kIOReturnSuccess, let result = DisplayDDCProtocol.decode(bytes, displayID: displayID) { return result }
        }
        return nil
    }

    private func write(_ bytes: [UInt8], to endpoint: Endpoint) -> Bool {
        guard let api else { return false }
        Thread.sleep(forTimeInterval: 0.01)
        var bytes = bytes
        return bytes.withUnsafeMutableBytes {
            api.write(endpoint.service, endpoint.chip, 0x51, $0.baseAddress, UInt32($0.count)) == kIOReturnSuccess
        }
    }

    private func endpoint(for displayID: UInt32) -> Endpoint? {
        guard let api, CGDisplayIsOnline(displayID) != 0, CGDisplayIsBuiltin(displayID) == 0 else { return nil }
        let vendor = CGDisplayVendorNumber(displayID)
        let product = CGDisplayModelNumber(displayID)
        let serial = CGDisplaySerialNumber(displayID)
        guard vendor != 0, product != 0 else { return nil }

        let root = IORegistryGetRootEntry(kIOMainPortDefault)
        defer { IOObjectRelease(root) }
        var iterator: io_iterator_t = 0
        guard IORegistryEntryCreateIterator(root, kIOServicePlane, UInt32(kIORegistryIterateRecursively), &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }

        var matchesDisplay = false
        var result: Endpoint?
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            if IOObjectConformsTo(entry, "IOMobileFramebuffer") != 0 {
                let attributes = IORegistryEntrySearchCFProperty(entry, kIOServicePlane, "DisplayAttributes" as CFString, kCFAllocatorDefault, UInt32(kIORegistryIterateRecursively)) as? [String: Any]
                let identity = attributes?["ProductAttributes"] as? [String: Any]
                matchesDisplay = (identity?["LegacyManufacturerID"] as? NSNumber)?.uint32Value == vendor &&
                    (identity?["ProductID"] as? NSNumber)?.uint32Value == product &&
                    (identity?["SerialNumber"] as? NSNumber)?.uint32Value == serial
                continue
            }
            guard matchesDisplay, IOObjectConformsTo(entry, "DCPAVServiceProxy") != 0,
                  property("Location", on: entry) as? String == "External",
                  let service = api.create(kCFAllocatorDefault, entry)?.takeRetainedValue() else { continue }
            // Identical displays without unique serials must never be guessed.
            guard result == nil else { return nil }
            var parent: io_registry_entry_t = 0
            var chip: UInt32 = 0x37
            if IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent) == KERN_SUCCESS {
                if property("EPICProviderClass", on: parent) as? String == "AppleDCPMCDP29XX" { chip = 0xb7 }
                IOObjectRelease(parent)
            }
            result = Endpoint(service: service, chip: chip)
        }
        return result
    }

    private func property(_ name: String, on entry: io_registry_entry_t) -> CFTypeRef? {
        IORegistryEntryCreateCFProperty(entry, name as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }
}

nonisolated private final class DDCIOKitAPI {
    typealias Create = @convention(c) (CFAllocator?, io_service_t) -> Unmanaged<CFTypeRef>?
    typealias Transfer = @convention(c) (CFTypeRef, UInt32, UInt32, UnsafeMutableRawPointer?, UInt32) -> IOReturn
    let create: Create
    let read: Transfer
    let write: Transfer
    private let handle: UnsafeMutableRawPointer

    init?() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY | RTLD_LOCAL) else { return nil }
        guard let create = dlsym(handle, "IOAVServiceCreateWithService"),
              let read = dlsym(handle, "IOAVServiceReadI2C"),
              let write = dlsym(handle, "IOAVServiceWriteI2C") else { dlclose(handle); return nil }
        self.handle = handle
        self.create = unsafeBitCast(create, to: Create.self)
        self.read = unsafeBitCast(read, to: Transfer.self)
        self.write = unsafeBitCast(write, to: Transfer.self)
    }

    deinit { dlclose(handle) }
}
