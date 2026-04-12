import SwiftUI

enum AppTint: String, CaseIterable, Identifiable {
    case blue
    case teal
    case green
    case orange
    case coral
    case red
    case pink
    case indigo
    case brown
    case graphite

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .blue:
            return "Blue"
        case .teal:
            return "Teal"
        case .green:
            return "Green"
        case .orange:
            return "Orange"
        case .coral:
            return "Coral"
        case .red:
            return "Red"
        case .pink:
            return "Pink"
        case .indigo:
            return "Indigo"
        case .brown:
            return "Brown"
        case .graphite:
            return "Graphite"
        }
    }

    var color: Color {
        switch self {
        case .blue:
            return .blue
        case .teal:
            return .teal
        case .green:
            return .green
        case .orange:
            return .orange
        case .coral:
            return Color(red: 0.95, green: 0.45, blue: 0.35)
        case .red:
            return .red
        case .pink:
            return .pink
        case .indigo:
            return .indigo
        case .brown:
            return .brown
        case .graphite:
            return Color(red: 0.36, green: 0.40, blue: 0.48)
        }
    }

    static func resolved(_ rawValue: String?) -> AppTint {
        guard let rawValue, let tint = AppTint(rawValue: rawValue) else {
            return .blue
        }

        return tint
    }
}
