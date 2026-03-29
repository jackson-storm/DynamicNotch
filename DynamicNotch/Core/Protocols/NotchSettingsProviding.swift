import Foundation

enum NotchAnimationPreset: String, CaseIterable {
    case snappy
    case fast
    case balanced
    case slow
    case relaxed

    var title: String {
        switch self {
        case .snappy:
            return "Faster"
        case .fast:
            return "Fast"
        case .balanced:
            return "Balanced"
        case .slow:
            return "Slow"
        case .relaxed:
            return "Slower"
        }
    }

    var symbolName: String {
        switch self {
        case .snappy:
            return "hare.fill"
        case .fast:
            return "speedometer"
        case .balanced:
            return ""
        case .slow:
            return "hourglass"
        case .relaxed:
            return "tortoise.fill"
        }
    }

    var description: String {
        switch self {
        case .snappy:
            return "The fastest notch motion with the tightest response."
        case .fast:
            return "A quicker preset that stays smoother than the fastest mode."
        case .balanced:
            return "Default motion with a balanced spring feel for everyday use."
        case .slow:
            return "A calmer preset with gentler motion than the default."
        case .relaxed:
            return "The slowest and softest notch motion preset."
        }
    }
}

protocol NotchSettingsProviding: AnyObject {
    var notchWidth: Int { get }
    var notchHeight: Int { get }
    var displayLocation: NotchDisplayLocation { get }
    var notchAnimationPreset: NotchAnimationPreset { get }
}
