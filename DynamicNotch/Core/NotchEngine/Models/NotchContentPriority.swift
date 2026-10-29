import Foundation
import SwiftUI

enum NotchContentPriority {
    enum Key: String, CaseIterable, Identifiable {
        case focus
        case hotspot
        case download
        case trayActive
        case airDropTransferActive
        case nowPlaying
        case timer
        case calendar
        case screenRecording
        case vpn

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
            case .airDropTransferActive:
                NotchContentPriority.airDropTransferActive
            case .nowPlaying:
                NotchContentPriority.nowPlaying
            case .timer:
                NotchContentPriority.timer
            case .calendar:
                NotchContentPriority.calendar
            case .screenRecording:
                NotchContentPriority.screenRecording
            case .vpn:
                NotchContentPriority.vpn
            }
        }
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .focus:
                "settings.notch.priorities.row.focus"
            case .hotspot:
                "settings.notch.priorities.row.hotspot"
            case .download:
                "settings.notch.priorities.row.downloads"
            case .trayActive:
                "settings.notch.priorities.row.trayActive"
            case .airDropTransferActive:
                "settings.notch.priorities.row.airDropTransferActive"
            case .nowPlaying:
                "settings.notch.priorities.row.nowPlaying"
            case .timer:
                "settings.notch.priorities.row.timer"
            case .screenRecording:
                "settings.notch.priorities.row.screenRecording"
            case .calendar:
                "settings.notch.priorities.row.calendar"
            case .vpn:
                "settings.notch.priorities.row.vpn"
            }
        }
        
        var image: String {
            switch self {
            case .focus:
                return "moon.fill"
            case .hotspot:
                return "personalhotspot"
            case .download:
                return "arrow.down.circle.fill"
            case .trayActive:
                return "tray.full.fill"
            case .airDropTransferActive:
                return "airdrop.white"
            case .nowPlaying:
                return "music.note"
            case .timer:
                return "timer"
            case .screenRecording:
                return "record.circle"
            case .calendar:
                return "calendar"
            case .vpn:
                return "network.badge.shield.half.filled"
            }
        }
        
        var color: Color {
            switch self {
            case .focus:
                    .indigo
            case .hotspot:
                    .green
            case .download:
                    .blue
            case .trayActive:
                    .black
            case .airDropTransferActive:
                    .blue
            case .nowPlaying:
                    .pink
            case .timer:
                    .orange
            case .screenRecording:
                    .red
            case .calendar:
                    .blue
            case .vpn:
                    .blue
            }
        }
    }

    static let overrideStorageKey = "settings.notch.priorityOverrides"
    static let priorityRange: ClosedRange<Int> = 0...20
    static let configurableKeys: [Key] = [
        .focus,
        .hotspot,
        .vpn,
        .download,
        .trayActive,
        .airDropTransferActive,
        .nowPlaying,
        .timer,
        .calendar,
        .screenRecording,
    ]

    static let `default` = 0
    static let focus = 1
    static let hotspot = 2
    static let vpn = 3
    static let download = 4
    static let trayActive = 5
    static let airDropTransferActive = 6
    static let nowPlaying = 7
    static let timer = 8
    static let calendar = 9
    static let screenRecording = 10

    static let dragAndDrop = 10001
    static let softwareUpdate = 10002
    static let lockScreen = 10003
    static let onboarding = 10004
    static let faceID = 10005
    static let localTimerSetup = 10006

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

extension Notification.Name {
    static let notchContentPrioritiesDidChange = Notification.Name(
        "DynamicNotch.notchContentPrioritiesDidChange"
    )
}
