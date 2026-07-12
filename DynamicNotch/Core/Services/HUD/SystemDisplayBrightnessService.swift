import CoreGraphics
import Foundation
import IOKit
import IOKit.graphics

@MainActor
final class SystemDisplayBrightnessService {
    private let displayServicesBridge: DisplayServicesBridge

    // MARK: - Smooth ramp state (main thread only)

    /// Same recipe the polished notch apps (Alcove/Atoll) use: consume the
    /// brightness key so macOS draws no OSD, then animate to the target ourselves
    /// with a short software ramp of *immediate* writes. We never call the smooth
    /// private setter — on Apple-Silicon built-ins it doesn't reach the target and
    /// also corrupts `DisplayServicesGetBrightness` (it starts returning 1.0).
    private var rampTimer: Timer?
    private var rampCurrent: Float = 0.5
    private var rampTarget: Float = 0.5

    private let rampTickInterval: TimeInterval = 1.0 / 60.0
    private let rampEaseFactor: Float = 0.34
    private let rampMinStep: Float = 0.006
    private let rampSnapEpsilon: Float = 0.002

    init(displayServicesBridge: DisplayServicesBridge = .shared) {
        self.displayServicesBridge = displayServicesBridge
    }

    deinit {
        rampTimer?.invalidate()
    }

    func adjust(direction: MediaKeyDirection, granularity: MediaKeyGranularity) -> Int {
        let delta = stepSize(for: granularity) * (direction == .increase ? 1 : -1)

        let base: Float
        if rampTimer != nil {
            // Mid-ramp (key held / repeated): accumulate onto the moving target.
            base = rampTarget
        } else {
            // Fresh gesture: seed from the panel's real brightness so we pick up
            // anything the system changed on its own (auto-brightness, unlock,
            // opening the lid) and never jump from a stale value.
            rampCurrent = currentBrightness
            base = rampCurrent
        }

        let target = max(0, min(1, base + delta))
        rampTarget = target
        startRampIfNeeded()
        return percentValue(for: target)
    }

    /// Immediately jumps to `value` (no ramp). Kept for programmatic callers.
    @discardableResult
    func setBrightness(_ value: Float) -> Int {
        let clampedValue = max(0, min(1, value))
        rampTimer?.invalidate()
        rampTimer = nil
        rampCurrent = clampedValue
        rampTarget = clampedValue
        applyBrightness(clampedValue)
        return percentValue(for: clampedValue)
    }

    // MARK: - Ramp driving

    private func startRampIfNeeded() {
        guard rampTimer == nil else { return }
        let timer = Timer(timeInterval: rampTickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.rampTick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        rampTimer = timer
    }

    private func rampTick() {
        let remaining = rampTarget - rampCurrent

        if abs(remaining) <= rampSnapEpsilon {
            rampCurrent = rampTarget
            applyBrightness(rampTarget)
            rampTimer?.invalidate()
            rampTimer = nil
            return
        }

        var delta = remaining * rampEaseFactor
        if abs(delta) < rampMinStep {
            delta = remaining > 0 ? min(remaining, rampMinStep) : max(remaining, -rampMinStep)
        }

        rampCurrent += delta
        applyBrightness(rampCurrent)
    }

    /// One immediate write to the panel. Never uses the smooth setter (see above);
    /// falls back to IOKit for non-DisplayServices displays.
    private func applyBrightness(_ value: Float) {
        let clampedValue = max(0, min(1, value))
        let displayID = targetDisplayID()

        if let result = displayServicesBridge.setBrightness(displayID: displayID, value: clampedValue),
           result == kIOReturnSuccess {
            return
        }

        guard let service = matchingDisplayService(for: displayID) else {
            return
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
            // Match the system: 16 brightness notches across the range.
            return 1.0 / 16.0
        case .fine:
            // Match the system's Option+Shift quarter step.
            return 1.0 / 64.0
        }
    }

    private func percentValue(for scalar: Float) -> Int {
        Int((max(0, min(1, scalar)) * 100).rounded())
    }
}
