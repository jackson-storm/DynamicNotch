import Foundation

struct NotchContentDescriptor: Equatable {
    let id: String
    let stackID: String
    let defaultPriority: Int
    let priorityKey: NotchContentPriority.Key?

    var priority: Int {
        guard let priorityKey else {
            return defaultPriority
        }

        return NotchContentPriority.resolvedValue(for: priorityKey)
    }

    init(
        id: String,
        stackID: String? = nil,
        priority: Int = NotchContentPriority.default,
        priorityKey: NotchContentPriority.Key? = nil
    ) {
        self.id = id
        self.stackID = stackID ?? id
        self.defaultPriority = priority
        self.priorityKey = priorityKey
    }

    init(
        id: String,
        stackID: String? = nil,
        priorityKey: NotchContentPriority.Key
    ) {
        self.init(
            id: id,
            stackID: stackID,
            priority: priorityKey.defaultValue,
            priorityKey: priorityKey
        )
    }
}

enum NotchContentPriority {
    enum Key: String, CaseIterable, Identifiable {
        case focus
        case hotspot
        case download
        case trayActive
        case nowPlaying
        case timer
        case screenRecording

        var id: String { rawValue }

        var defaultValue: Int {
            switch self {
            case .focus:
                NotchContentPriority.focus
            case .hotspot:
                NotchContentPriority.hotspot
            case .download:
                NotchContentPriority.download
            case .trayActive:
                NotchContentPriority.trayActive
            case .nowPlaying:
                NotchContentPriority.nowPlaying
            case .timer:
                NotchContentPriority.timer
            case .screenRecording:
                NotchContentPriority.screenRecording
            }
        }

    }

    static let overrideStorageKey = "settings.notch.priorityOverrides"
    static let priorityRange: ClosedRange<Int> = 0...20
    static let configurableKeys: [Key] = [
        .focus,
        .hotspot,
        .download,
        .trayActive,
        .nowPlaying,
        .timer,
        .screenRecording
    ]

    static let `default` = 0
    static let focus = 1
    static let hotspot = 2
    static let download = 3
    static let trayActive = 4
    static let nowPlaying = 5
    static let timer = 6
    static let screenRecording = 7

    static let notchSizeWidth = 1000
    static let notchSizeHeight = 1001
    static let dragAndDrop = 1002
    static let lockScreen = 1003
    static let onboarding = 1004

    static func resolvedValue(for key: Key, defaults: UserDefaults = .standard) -> Int {
        overrideValues(defaults: defaults)[key.rawValue] ?? key.defaultValue
    }

    static func overrideValues(defaults: UserDefaults = .standard) -> [String: Int] {
        guard let storedValues = defaults.dictionary(forKey: overrideStorageKey) else {
            return [:]
        }

        return sanitizedOverrides(
            storedValues.compactMapValues { value in
                if let intValue = value as? Int {
                    return intValue
                }

                if let numberValue = value as? NSNumber {
                    return numberValue.intValue
                }

                return nil
            }
        )
    }

    static func sanitizedOverrides(_ overrides: [String: Int]) -> [String: Int] {
        overrides.reduce(into: [:]) { result, pair in
            guard let key = Key(rawValue: pair.key) else { return }
            let clampedValue = clamped(pair.value)

            guard clampedValue != key.defaultValue else { return }
            result[key.rawValue] = clampedValue
        }
    }

    static func clamped(_ priority: Int) -> Int {
        min(max(priority, priorityRange.lowerBound), priorityRange.upperBound)
    }
}

extension Notification.Name {
    static let notchContentPrioritiesDidChange = Notification.Name(
        "DynamicNotch.notchContentPrioritiesDidChange"
    )
}

enum NotchContentRegistry {
    enum HUD {
        static let system = NotchContentDescriptor(id: "hud.system")
        static let keyboard = NotchContentDescriptor(id: "hud.keyboard")
    }
    
    enum Power {
        static let charger = NotchContentDescriptor(id: "battery.charger")
        static let lowPower = NotchContentDescriptor(id: "battery.lowPower")
        static let fullPower = NotchContentDescriptor(id: "battery.fullPower")
    }

    enum Focus {
        static let active = NotchContentDescriptor(
            id: "focus.on",
            priorityKey: .focus
        )
        static let inactive = NotchContentDescriptor(id: "focus.off")
    }

    enum ScreenRecording {
        static let active = NotchContentDescriptor(
            id: "screen.recording",
            priorityKey: .screenRecording
        )
        static let inactive = NotchContentDescriptor(id: "screen.recording.inactive")
    }

    enum Network {
        static let bluetooth = NotchContentDescriptor(id: "bluetooth.connected")
        static let hotspot = NotchContentDescriptor(
            id: "hotspot.active",
            priorityKey: .hotspot
        )
        static let wifi = NotchContentDescriptor(id: "wifi.connected")
        static let vpn = NotchContentDescriptor(id: "vpn.connected")
        static let noInternet = NotchContentDescriptor(id: "network.noInternetConnection")
    }

    enum Media {
        static let nowPlaying = NotchContentDescriptor(
            id: "nowPlaying",
            priorityKey: .nowPlaying
        )
        static let download = NotchContentDescriptor(
            id: "download.active",
            priorityKey: .download
        )
        static let timer = NotchContentDescriptor(
            id: "clock.timer",
            priorityKey: .timer
        )
    }

    enum DragAndDrop {
        static let airDrop = NotchContentDescriptor(
            id: "airdrop",
            priority: NotchContentPriority.dragAndDrop
        )
        static let tray = NotchContentDescriptor(
            id: "tray",
            priority: NotchContentPriority.dragAndDrop
        )
        static let combined = NotchContentDescriptor(
            id: "dragAndDrop.combined",
            priority: NotchContentPriority.dragAndDrop
        )
        
        static let trayActive = NotchContentDescriptor(
            id: "tray.active",
            priorityKey: .trayActive
        )

        static let liveActivityIDs = [
            airDrop.id,
            tray.id,
            combined.id
        ]
    }

    enum LockScreen {
        static let activity = NotchContentDescriptor(
            id: "lockScreen",
            priority: NotchContentPriority.lockScreen
        )
    }

    enum NotchSize {
        static let width = NotchContentDescriptor(
            id: "notchSize.width",
            priority: NotchContentPriority.notchSizeWidth
        )
        static let height = NotchContentDescriptor(
            id: "notchSize.height",
            priority: NotchContentPriority.notchSizeHeight
        )
    }

    enum Onboarding {
        static let stackID = "onboarding"
        static let debugStackID = "onboarding.debug"
        static let priority = NotchContentPriority.onboarding

        static func id(forStep rawValue: String) -> String {
            "\(stackID).\(rawValue)"
        }

        #if DEBUG
        static func debugID(forStep rawValue: String) -> String {
            "\(debugStackID).\(rawValue)"
        }
        #endif
    }

    enum DebugSequence {
        static let prefix = "debug.sequence."

        static let focus = id(Focus.active.id)
        static let focusOff = id(Focus.inactive.id)
        static let screenRecording = id(ScreenRecording.active.id)
        static let screenRecordingInactive = id(ScreenRecording.inactive.id)
        static let hotspot = id(Network.hotspot.id)
        static let nowPlaying = id(Media.nowPlaying.id)
        static let download = id(Media.download.id)
        static let timer = id(Media.timer.id)
        static let bluetooth = id(Network.bluetooth.id)
        static let wifi = id(Network.wifi.id)
        static let vpn = id(Network.vpn.id)
        static let noInternet = id(Network.noInternet.id)
        static let charging = id("charger")
        static let lowPower = id("lowPower")
        static let fullPower = id("fullPower")
        static let hudBrightness = id("hud.brightness")
        static let hudKeyboard = id("hud.keyboard")
        static let hudVolume = id("hud.volume")

        static func id(_ suffix: String) -> String {
            "\(prefix)\(suffix)"
        }
    }
}
