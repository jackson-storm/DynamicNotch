import CoreGraphics
import Foundation
import IOKit
import IOKit.graphics

final class SystemDisplayBrightnessService {
    private let displayServicesBridge: DisplayServicesBridge

    /// Logical target of the most recent set — what the HUD shows and what the
    /// next key step accumulates from. The smooth private setter reports success
    /// but does not actually reach the requested value on Apple Silicon built-in
    /// displays, so reading brightness back gave a stale base and steps could not
    /// accumulate. Tracking the target ourselves fixes that.
    private var cachedBrightness: Float?

    init(displayServicesBridge: DisplayServicesBridge = .shared) {
        self.displayServicesBridge = displayServicesBridge
    }

    func adjust(direction: MediaKeyDirection, granularity: MediaKeyGranularity) -> Int {
        let base = cachedBrightness ?? currentBrightness
        let delta = stepSize(for: granularity) * (direction == .increase ? 1 : -1)
        return setBrightness(base + delta)
    }

    /// Sets brightness in one discrete step. The brightness key is consumed to
    /// hide the system OSD, so we must set the value ourselves. The only reliable
    /// private setter is the immediate one — the smooth variant reports success
    /// but doesn't reach the target on Apple Silicon built-in panels — so steps
    /// are discrete rather than a hardware-smooth ramp.
    @discardableResult
    func setBrightness(_ value: Float) -> Int {
        let clampedValue = max(0, min(1, value))
        let displayID = targetDisplayID()

        if let result = displayServicesBridge.setBrightness(displayID: displayID, value: clampedValue),
           result == kIOReturnSuccess {
            cachedBrightness = clampedValue
            return percentValue(for: clampedValue)
        }

        if let result = displayServicesBridge.setBrightnessSmooth(displayID: displayID, value: clampedValue),
           result == kIOReturnSuccess {
            cachedBrightness = clampedValue
            return percentValue(for: clampedValue)
        }

        guard let service = matchingDisplayService(for: displayID) else {
            return percentValue(for: cachedBrightness ?? currentBrightness)
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
            return percentValue(for: cachedBrightness ?? currentBrightness)
        }

        cachedBrightness = clampedValue
        return percentValue(for: clampedValue)
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
