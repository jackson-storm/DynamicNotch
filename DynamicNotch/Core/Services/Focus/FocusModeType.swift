import Foundation
import SwiftUI

enum FocusModeType: String, CaseIterable {
    case doNotDisturb = "com.apple.donotdisturb.mode"
    case work = "com.apple.focus.work"
    case personal = "com.apple.focus.personal"
    case sleep = "com.apple.focus.sleep"
    case driving = "com.apple.focus.driving"
    case fitness = "com.apple.focus.fitness"
    case gaming = "com.apple.focus.gaming"
    case mindfulness = "com.apple.focus.mindfulness"
    case reading = "com.apple.focus.reading"
    case reduceInterruptions = "com.apple.focus.reduce-interruptions"
    case custom = "com.apple.focus.custom"
    case unknown = ""

    var displayName: String {
        switch self {
        case .doNotDisturb: return "Do Not Disturb"
        case .work: return "Work"
        case .personal: return "Personal"
        case .sleep: return "Sleep"
        case .driving: return "Driving"
        case .fitness: return "Fitness"
        case .gaming: return "Gaming"
        case .mindfulness: return "Mindfulness"
        case .reading: return "Reading"
        case .reduceInterruptions: return "Reduce Interr."
        case .custom: return "Focus"
        case .unknown: return "Focus Mode"
        }
    }

    var icon: String {
        switch self {
        case .doNotDisturb: return "moon.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .sleep: return "bed.double.fill"
        case .driving: return "car.fill"
        case .fitness: return "figure.run"
        case .gaming: return "gamecontroller.fill"
        case .mindfulness: return "brain.head.profile"
        case .reading: return "book.closed.fill"
        case .reduceInterruptions: return "apple.intelligence"
        case .custom: return getCustomIconFromFile()
        case .unknown: return "moon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .doNotDisturb: return Color(red: 0.370, green: 0.360, blue: 0.902)
        case .work: return Color(red: 0.414, green: 0.769, blue: 0.863, opacity: 1.0)
        case .personal: return Color(red: 0.748, green: 0.354, blue: 0.948, opacity: 1.0)
        case .sleep: return Color(red: 0.341, green: 0.384, blue: 0.980)
        case .driving: return Color(red: 0.988, green: 0.561, blue: 0.153)
        case .fitness: return Color(red: 0.176, green: 0.804, blue: 0.459)
        case .gaming: return Color(red: 0.043, green: 0.518, blue: 1.000, opacity: 1.0)
        case .mindfulness: return Color(red: 0.361, green: 0.898, blue: 0.883, opacity: 1.0)
        case .reading: return Color(red: 1.000, green: 0.622, blue: 0.044, opacity: 1.0)
        case .reduceInterruptions: return Color(red: 0.686, green: 0.322, blue: 0.871, opacity: 1.0)
        case .custom: return getCustomAccentColorFromFile()
        case .unknown: return Color(red: 0.370, green: 0.360, blue: 0.902)
        }
    }
}

extension FocusModeType {
    init(identifier: String) {
        let normalized = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLowercased = normalized.lowercased()

        guard !normalized.isEmpty else {
            self = .doNotDisturb
            return
        }

        if let direct = FocusModeType(rawValue: normalized) ?? FocusModeType(rawValue: normalizedLowercased) {
            self = direct
            return
        }

        if normalizedLowercased == "com.apple.sleep.sleep-mode" {
            self = .sleep
            return
        }

        if normalizedLowercased.hasPrefix("com.apple.donotdisturb.mode.") {
            let suffix = String(normalizedLowercased.dropFirst("com.apple.donotdisturb.mode.".count))
            if !suffix.isEmpty && suffix != "default" {
                self = .custom
                return
            }
        }

        if let resolved = FocusModeType.allCases.first(where: {
            guard !$0.rawValue.isEmpty else { return false }
            return normalized.hasPrefix($0.rawValue) || normalizedLowercased.hasPrefix($0.rawValue)
        }) {
            self = resolved
            return
        }

        if normalizedLowercased.hasPrefix("com.apple.focus") {
            if normalizedLowercased == "com.apple.focus" || normalizedLowercased == "com.apple.focus.default" {
                self = .doNotDisturb
                return
            }
            self = .custom
            return
        }

        self = .doNotDisturb
    }

    static func resolve(identifier: String?, name: String?) -> FocusModeType {
        if let name, !name.isEmpty {
            if let match = FocusModeType.allCases.first(where: {
                guard !$0.displayName.isEmpty else { return false }
                return $0.displayName.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }) {
                return match
            }

            let lower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch lower {
            case "work", "работа": return .work
            case "personal", "personal-time", "личное": return .personal
            case "sleep", "sleep-mode", "сон": return .sleep
            case "driving", "за рулем": return .driving
            case "fitness", "тренировка": return .fitness
            case "gaming", "видеоигры", "игры": return .gaming
            case "mindfulness", "осознанность": return .mindfulness
            case "reading", "чтение": return .reading
            case "reduce-interruptions", "reduce interruptions": return .reduceInterruptions
            case "do not disturb", "dnd", "donotdisturb", "do-not-disturb", "default", "не беспокоить": return .doNotDisturb
            default: break
            }
        }

        if let identifier, !identifier.isEmpty {
            return FocusModeType(identifier: identifier)
        }

        if let name, !name.isEmpty {
            return .custom
        }

        return .doNotDisturb
    }

    private func getCustomIconFromFile() -> String {
        return FocusMetadataReader.shared.getIcon(for: DoNotDisturbManager.shared.currentFocusModeName, identifier: DoNotDisturbManager.shared.currentFocusModeIdentifier)
    }

    private func getCustomAccentColorFromFile() -> Color {
        return FocusMetadataReader.shared.getAccentColor(for: DoNotDisturbManager.shared.currentFocusModeName, identifier: DoNotDisturbManager.shared.currentFocusModeIdentifier)
    }
}

internal final class FocusMetadataReader {
    private let pathToDatabase: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/DoNotDisturb/DB/ModeConfigurations.json")

    struct DNDConfigRoot: Codable {
        let data: [DNDDataEntry]
    }

    struct DNDDataEntry: Codable {
        let modeConfigurations: [String: DNDModeWrapper]
    }

    struct DNDModeWrapper: Codable {
        let mode: DNDMode
    }

    struct DNDMode: Codable {
        let name: String
        let modeIdentifier: String
        let symbolImageName: String?
        let tintColorName: String?
    }

    private init() {}
    static let shared = FocusMetadataReader()

    private func getModeConfig(for focusName: String, identifier: String? = nil) -> DNDMode? {
        let trimmedName = focusName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIdentifier = identifier?.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let data = try Data(contentsOf: pathToDatabase)
            let root = try JSONDecoder().decode(DNDConfigRoot.self, from: data)

            for entry in root.data {
                for wrapper in entry.modeConfigurations.values {
                    let mode = wrapper.mode

                    if let id = trimmedIdentifier, !id.isEmpty,
                       mode.modeIdentifier.compare(id, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                        return mode
                    }

                    if !trimmedName.isEmpty,
                       mode.name.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                        return mode
                    }
                }
            }
        } catch {
            // Ignored since app might not have Full Disk Access
        }

        return nil
    }

    func getDisplayName(for focus: String, identifier: String? = nil) -> String {
        guard let mode = getModeConfig(for: focus, identifier: identifier) else { return "" }
        return mode.name
    }

    func getIcon(for focus: String, identifier: String? = nil) -> String {
        guard let mode = getModeConfig(for: focus, identifier: identifier) else { return "app.badge" }
        return mode.symbolImageName ?? "app.badge"
    }

    func getAccentColor(for focus: String, identifier: String? = nil) -> Color {
        guard let mode = getModeConfig(for: focus, identifier: identifier),
              let colorName = mode.tintColorName else { return .indigo }
        
        return stringToColor(for: colorName)
    }

    private func stringToColor(for string: String) -> Color {
        let cleanName = string.lowercased()
            .replacingOccurrences(of: "system", with: "")
            .replacingOccurrences(of: "color", with: "")
        
        switch cleanName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .gray
        default: return .indigo
        }
    }
}
