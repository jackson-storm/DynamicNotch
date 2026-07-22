import Foundation
import SwiftUI

enum NotchContentPriority {
    enum Key: String, CaseIterable, Identifiable {
        case homePage
        case focus
        case hotspot
        case download
        case trayActive
        case nowPlaying
        case timer
        case calendar
        case fileConverterActive
        case screenRecording

        var id: String { rawValue }

        var defaultValue: Int {
            switch self {
            case .homePage:
                NotchContentPriority.homePage
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
            case .calendar:
                NotchContentPriority.calendar
            case .fileConverterActive:
                NotchContentPriority.fileConverterActive
            case .screenRecording:
                NotchContentPriority.screenRecording
            }
        }
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .homePage:
                "settings.notch.priorities.row.homePage"
            case .focus:
                "settings.notch.priorities.row.focus"
            case .hotspot:
                "settings.notch.priorities.row.hotspot"
            case .download:
                "settings.notch.priorities.row.downloads"
            case .trayActive:
                "settings.notch.priorities.row.trayActive"
            case .nowPlaying:
                "settings.notch.priorities.row.nowPlaying"
            case .timer:
                "settings.notch.priorities.row.timer"
            case .screenRecording:
                "settings.notch.priorities.row.screenRecording"
            case .fileConverterActive:
                "settings.notch.priorities.row.fileConverterActive"
            case .calendar:
                "settings.notch.priorities.row.calendar"
            }
        }
        
        var image: String {
            switch self {
            case .homePage:
                return "house.fill"
            case .focus:
                return "moon.fill"
            case .hotspot:
                return "personalhotspot"
            case .download:
                return "arrow.down.circle.fill"
            case .trayActive:
                return "tray.full.fill"
            case .fileConverterActive:
                return "arrow.trianglehead.2.counterclockwise.rotate.90"
            case .nowPlaying:
                return "music.note"
            case .timer:
                return "timer"
            case .screenRecording:
                return "record.circle"
            case .calendar:
                return "calendar"
            }
        }
        
        var color: Color {
            switch self {
            case .homePage:
                    .blue
            case .focus:
                    .indigo
            case .hotspot:
                    .green
            case .download:
                    .blue
            case .trayActive:
                    .black
            case .fileConverterActive:
                    .green
            case .nowPlaying:
                    .pink
            case .timer:
                    .orange
            case .screenRecording:
                    .red
            case .calendar:
                    .blue
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
        .calendar,
        .fileConverterActive,
        .screenRecording,
    ]

    static let `default` = 0
    static let focus = 1
    static let hotspot = 2
    static let download = 3
    static let trayActive = 4
    static let nowPlaying = 5
    static let timer = 6
    static let calendar = 7
    static let fileConverterActive = 8
    static let screenRecording = 9

    static let homePage = -10000
    static let notchSizeWidth = 10000
    static let notchSizeHeight = 10001
    static let dragAndDrop = 10002
    static let softwareUpdate = 10003
    static let lockScreen = 10004
    static let onboarding = 10005

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
