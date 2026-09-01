internal import AppKit
import CoreGraphics
import Foundation

#if canImport(ApplicationServices)
import ApplicationServices
#endif

enum MediaKeyCode {
    static let systemDefinedEventType: UInt32 = 14
    static let volumeUp: Int32 = 0
    static let volumeDown: Int32 = 1
    static let brightnessUp: Int32 = 2
    static let brightnessDown: Int32 = 3
    static let mute: Int32 = 7
}

private enum MediaKeyModifiers {
    static let considered: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
    static let quietVolume: NSEvent.ModifierFlags = [.shift]
    static let fineAdjustment: NSEvent.ModifierFlags = [.option, .shift]
}

enum MediaKeyDirection {
    case increase
    case decrease
}

enum MediaKeyGranularity {
    case standard
    case fine
}

struct SystemMediaKeyTapConfiguration {
    var interceptVolume: Bool
    var interceptBrightness: Bool

    static let disabled = SystemMediaKeyTapConfiguration(
        interceptVolume: false,
        interceptBrightness: false
    )

    var interceptsAnyMediaKey: Bool {
        interceptVolume || interceptBrightness
    }

    func intercepts(keyCode: Int32, modifiers: NSEvent.ModifierFlags) -> Bool {
        guard interceptsKeyCode(keyCode) else {
            return false
        }

        let activeModifiers = modifiers.intersection(MediaKeyModifiers.considered)
        return activeModifiers.isEmpty
            || activeModifiers == MediaKeyModifiers.quietVolume
            || activeModifiers == MediaKeyModifiers.fineAdjustment
    }

    private func interceptsKeyCode(_ keyCode: Int32) -> Bool {
        switch keyCode {
        case MediaKeyCode.volumeUp,
             MediaKeyCode.volumeDown,
             MediaKeyCode.mute:
            return interceptVolume
        case MediaKeyCode.brightnessUp,
             MediaKeyCode.brightnessDown:
            return interceptBrightness
        default:
            return false
        }
    }
}

protocol SystemMediaKeyTapDelegate: AnyObject {
    func mediaKeyTap(
        _ tap: SystemMediaKeyTap,
        didReceiveVolumeCommand direction: MediaKeyDirection,
        granularity: MediaKeyGranularity,
        modifiers: NSEvent.ModifierFlags
    )

    func mediaKeyTapDidToggleMute(_ tap: SystemMediaKeyTap)

    func mediaKeyTap(
        _ tap: SystemMediaKeyTap,
        didReceiveBrightnessCommand direction: MediaKeyDirection,
        granularity: MediaKeyGranularity,
        modifiers: NSEvent.ModifierFlags
    )
}

final class SystemMediaKeyTap {
    weak var delegate: SystemMediaKeyTapDelegate?
    var configuration: SystemMediaKeyTapConfiguration = .disabled {
        didSet {
            updateTapState()
        }
    }
    var isAccessibilityTrusted: Bool {
        currentAccessibilityTrustState()
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hasRequestedAccessibilityPrompt = false
    private var isTapEnabled = false
    private var interceptedKeyCodes: Set<Int32> = []

    private var systemDefinedEvent: CGEventType? {
        CGEventType(rawValue: MediaKeyCode.systemDefinedEventType)
    }

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else {
            return true
        }

        requestAccessibilityPermissionIfNeeded()

        guard let systemDefinedEvent else {
            NSLog("Failed to resolve the system-defined CGEvent type.")
            return false
        }

        let eventMask = CGEventMask(1) << systemDefinedEvent.rawValue
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let tap = Unmanaged<SystemMediaKeyTap>.fromOpaque(userInfo).takeUnretainedValue()
            return tap.handleEvent(type: type, event: event)
        }

        guard let createdTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            NSLog("Failed to create the media key event tap. Accessibility permission may be missing.")
            return false
        }

        eventTap = createdTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, createdTap, 0)

        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        let shouldEnableTap = configuration.interceptsAnyMediaKey
        CGEvent.tapEnable(tap: createdTap, enable: shouldEnableTap)
        isTapEnabled = shouldEnableTap
        return true
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isTapEnabled = false
        interceptedKeyCodes.removeAll()
    }

    func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap, configuration.interceptsAnyMediaKey {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                isTapEnabled = true
            }
            return Unmanaged.passUnretained(event)
        }

        guard let systemDefinedEvent,
              type == systemDefinedEvent,
              let nsEvent = NSEvent(cgEvent: event),
              nsEvent.subtype.rawValue == 8 else {
            return Unmanaged.passUnretained(event)
        }

        let data1 = nsEvent.data1
        let keyCode = Int32((data1 & 0xFFFF0000) >> 16)
        let keyFlags = data1 & 0x0000FFFF
        let isKeyDown = ((keyFlags & 0xFF00) >> 8) == 0xA
        let modifiers = nsEvent.modifierFlags

        guard isKeyDown else {
            return interceptedKeyCodes.remove(keyCode) == nil ? Unmanaged.passUnretained(event) : nil
        }

        guard configuration.intercepts(keyCode: keyCode, modifiers: modifiers) else {
            interceptedKeyCodes.remove(keyCode)
            return Unmanaged.passUnretained(event)
        }

        interceptedKeyCodes.insert(keyCode)
        let granularity = granularity(for: nsEvent)

        switch keyCode {
        case MediaKeyCode.volumeUp:
            delegate?.mediaKeyTap(self, didReceiveVolumeCommand: .increase, granularity: granularity, modifiers: modifiers)

        case MediaKeyCode.volumeDown:
            delegate?.mediaKeyTap(self, didReceiveVolumeCommand: .decrease, granularity: granularity, modifiers: modifiers)

        case MediaKeyCode.mute:
            delegate?.mediaKeyTapDidToggleMute(self)

        case MediaKeyCode.brightnessUp:
            // Consume the brightness key. On macOS 26 the only way to hide the
            // system OSD (drawn by MenuBarAgent, unkillable) is to swallow the key
            // so the OS never shows it — the same way volume keys are handled. The
            // trade-off is discrete steps, since the smooth hardware ramp is only
            // available when the key isn't consumed.
            delegate?.mediaKeyTap(self, didReceiveBrightnessCommand: .increase, granularity: granularity, modifiers: modifiers)

        case MediaKeyCode.brightnessDown:
            delegate?.mediaKeyTap(self, didReceiveBrightnessCommand: .decrease, granularity: granularity, modifiers: modifiers)

        default:
            interceptedKeyCodes.remove(keyCode)
            return Unmanaged.passUnretained(event)
        }

        return nil
    }

    private func granularity(for event: NSEvent) -> MediaKeyGranularity {
        let modifiers = event.modifierFlags
        return modifiers.contains(.option) && modifiers.contains(.shift) ? .fine : .standard
    }

    private func updateTapState() {
        guard let eventTap else {
            return
        }

        let shouldEnableTap = configuration.interceptsAnyMediaKey
        guard shouldEnableTap != isTapEnabled else {
            return
        }

        CGEvent.tapEnable(tap: eventTap, enable: shouldEnableTap)
        isTapEnabled = shouldEnableTap

        if !shouldEnableTap {
            interceptedKeyCodes.removeAll()
        }
    }

    deinit {
        stop()
    }
}

#if canImport(ApplicationServices)
private extension SystemMediaKeyTap {
    func currentAccessibilityTrustState() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermissionIfNeeded() {
        guard !AXIsProcessTrusted(), !hasRequestedAccessibilityPrompt else {
            return
        }

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        hasRequestedAccessibilityPrompt = true
    }
}
#else
private extension SystemMediaKeyTap {
    func currentAccessibilityTrustState() -> Bool { true }
    func requestAccessibilityPermissionIfNeeded() {}
}
#endif
