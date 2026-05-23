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
        case .custom: return "app.badge"
        case .unknown: return "moon.fill"
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

        return .doNotDisturb
    }
}

func test(identifier: String?, name: String?) {
    let resolved = FocusModeType.resolve(identifier: identifier, name: name)
    print("name='\(name ?? "nil")', id='\(identifier ?? "nil")' => \(resolved) (icon: \(resolved.icon))")
}

test(identifier: "com.apple.focus", name: "Не беспокоить")
test(identifier: "com.apple.donotdisturb.mode.default", name: "Не беспокоить")
test(identifier: "com.apple.focus.driving", name: "За рулем")
test(identifier: "com.apple.donotdisturb.mode.driving", name: "За рулем")
test(identifier: "com.apple.donotdisturb.mode", name: nil)
test(identifier: "com.apple.donotdisturb.mode", name: "Не беспокоить")
test(identifier: nil, name: "Не беспокоить")
test(identifier: "com.apple.focus", name: "Do Not Disturb")
test(identifier: "com.apple.focus", name: nil)
test(identifier: "com.apple.donotdisturb.mode.graduationcap.fill", name: "Study")
