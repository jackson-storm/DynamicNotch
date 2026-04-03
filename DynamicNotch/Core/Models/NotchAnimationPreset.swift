import Foundation
import SwiftUI

enum NotchAnimationPreset: String, CaseIterable {
    case snappy
    case fast
    case balanced
    case slow
    case relaxed

    var title: LocalizedStringKey {
        switch self {
        case .snappy:
            return "settings.general.animation.faster"
        case .fast:
            return "settings.general.animation.fast"
        case .balanced:
            return "settings.general.animation.balanced"
        case .slow:
            return "settings.general.animation.slow"
        case .relaxed:
            return "settings.general.animation.slower"
        }
    }

    var symbolName: String {
        switch self {
        case .snappy:
            return "hare.fill"
        case .fast:
            return "speedometer"
        case .balanced:
            return "gauge"
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
