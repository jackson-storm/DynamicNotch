import CoreGraphics
import Foundation
import IOKit
import IOKit.graphics

final class SystemDisplayBrightnessService {
    private let displayServicesBridge: DisplayServicesBridge

    init(displayServicesBridge: DisplayServicesBridge = .shared) {
        self.displayServicesBridge = displayServicesBridge
    }

    func adjust(direction: MediaKeyDirection, granularity: MediaKeyGranularity) -> Int {
        let delta = stepSize(for: granularity) * (direction == .increase ? 1 : -1)
        return setBrightness(currentBrightness + delta)
    }

    @discardableResult
    func setBrightness(_ value: Float) -> Int {
        let clampedValue = max(0, min(1, value))
        let displayID = targetDisplayID()

        if let result = displayServicesBridge.setBrightness(displayID: displayID, value: clampedValue),
           result == kIOReturnSuccess {
            return percentValue(for: clampedValue)
        }

        guard let service = matchingDisplayService(for: displayID) else {
            return percentValue(for: currentBrightness)
        }

        let status = IODisplaySetFloatParameter(
            service,
            0,
            kIODisplayBrightnessKey as CFString,
            clampedValue
        )
        IOObjectRelease(service)

        if status != kIOReturnSuccess {
            NSLog("Failed to set display brightness: \(status)")
        }

        return percentValue(for: currentBrightness)
    }

    var currentBrightness: Float {
        let displayID = targetDisplayID()

        if let brightnessResult = displayServicesBridge.getBrightness(displayID: displayID),
           brightnessResult.status == kIOReturnSuccess {
            return max(0, min(1, brightnessResult.value))
        }

        guard let service = matchingDisplayService(for: displayID) else {
            return 0.5
        }

        var brightness: Float = 0.5
        let status = IODisplayGetFloatParameter(
            service,
            0,
            kIODisplayBrightnessKey as CFString,
            &brightness
        )
        IOObjectRelease(service)

        guard status == kIOReturnSuccess else {
            return 0.5
        }

        return max(0, min(1, brightness))
    }

    private func targetDisplayID() -> CGDirectDisplayID {
        var displayCount: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &displayCount)

        guard displayCount > 0 else {
            return CGMainDisplayID()
        }

        var displays = Array(repeating: CGDirectDisplayID(), count: Int(displayCount))
        CGGetOnlineDisplayList(displayCount, &displays, &displayCount)

        return displays.first(where: { CGDisplayIsBuiltin($0) != 0 }) ?? CGMainDisplayID()
    }

    private func matchingDisplayService(for displayID: CGDirectDisplayID) -> io_service_t? {
        let vendorID = CGDisplayVendorNumber(displayID)
        let productID = CGDisplayModelNumber(displayID)
        let serialNumber = CGDisplaySerialNumber(displayID)

        var iterator = io_iterator_t()
        let status = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )

        guard status == KERN_SUCCESS else {
            return nil
        }

        defer { IOObjectRelease(iterator) }

        while case let service = IOIteratorNext(iterator), service != 0 {
            guard let infoDictionary = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayOnlyPreferredName)).takeRetainedValue() as? [String: Any] else {
                IOObjectRelease(service)
                continue
            }

            let serviceVendorID = infoDictionary[kDisplayVendorID as String] as? UInt32
            let serviceProductID = infoDictionary[kDisplayProductID as String] as? UInt32
            let serviceSerialNumber = infoDictionary[kDisplaySerialNumber as String] as? UInt32

            let vendorMatches = serviceVendorID == vendorID
            let productMatches = serviceProductID == productID
            let serialMatches = serialNumber == 0 || serviceSerialNumber == serialNumber

            if vendorMatches && productMatches && serialMatches {
                return service
            }

            IOObjectRelease(service)
        }

        return nil
    }

    private func stepSize(for granularity: MediaKeyGranularity) -> Float {
        switch granularity {
        case .standard:
            return 1.0 / 16.0
        case .fine:
            return 1.0 / 64.0
        }
    }

    private func percentValue(for scalar: Float) -> Int {
        Int((max(0, min(1, scalar)) * 100).rounded())
    }
}
