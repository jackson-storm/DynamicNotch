internal import AppKit
import CoreGraphics
import Foundation

#if canImport(ApplicationServices)
import ApplicationServices
#endif

private enum MediaKeyCode {
    static let systemDefinedEventType: UInt32 = 14
    static let volumeUp: Int32 = 0
    static let volumeDown: Int32 = 1
    static let brightnessUp: Int32 = 2
    static let brightnessDown: Int32 = 3
    static let mute: Int32 = 7
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
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
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

        if !isKeyDown {
            return shouldHandleKeyCode(keyCode) ? nil : Unmanaged.passUnretained(event)
        }

        let granularity = granularity(for: nsEvent)

        switch keyCode {
        case MediaKeyCode.volumeUp:
            guard configuration.interceptVolume else {
                return Unmanaged.passUnretained(event)
            }
            delegate?.mediaKeyTap(self, didReceiveVolumeCommand: .increase, granularity: granularity, modifiers: nsEvent.modifierFlags)
            return nil

        case MediaKeyCode.volumeDown:
            guard configuration.interceptVolume else {
                return Unmanaged.passUnretained(event)
            }
            delegate?.mediaKeyTap(self, didReceiveVolumeCommand: .decrease, granularity: granularity, modifiers: nsEvent.modifierFlags)
            return nil

        case MediaKeyCode.mute:
            guard configuration.interceptVolume else {
                return Unmanaged.passUnretained(event)
            }
            delegate?.mediaKeyTapDidToggleMute(self)
            return nil

        case MediaKeyCode.brightnessUp:
            guard configuration.interceptBrightness else {
                return Unmanaged.passUnretained(event)
            }
            delegate?.mediaKeyTap(self, didReceiveBrightnessCommand: .increase, granularity: granularity, modifiers: nsEvent.modifierFlags)
            return nil

        case MediaKeyCode.brightnessDown:
            guard configuration.interceptBrightness else {
                return Unmanaged.passUnretained(event)
            }
            delegate?.mediaKeyTap(self, didReceiveBrightnessCommand: .decrease, granularity: granularity, modifiers: nsEvent.modifierFlags)
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func shouldHandleKeyCode(_ keyCode: Int32) -> Bool {
        switch keyCode {
        case MediaKeyCode.volumeUp,
             MediaKeyCode.volumeDown,
             MediaKeyCode.mute:
            return configuration.interceptVolume
        case MediaKeyCode.brightnessUp,
             MediaKeyCode.brightnessDown:
            return configuration.interceptBrightness
        default:
            return false
        }
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
