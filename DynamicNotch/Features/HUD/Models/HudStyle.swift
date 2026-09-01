import SwiftUI

enum HudStyle: String, CaseIterable {
    case standard
    case compact
    case minimal
    case expandedCompact
    case expandedDetailed

    var title: LocalizedStringKey {
        switch self {
        case .standard:
            return "settings.hud.style.standard"
        case .compact:
            return "settings.hud.style.compact"
        case .minimal:
            return "settings.hud.style.minimal"
        case .expandedCompact:
            return "settings.hud.style.expandedCompact"
        case .expandedDetailed:
            return "settings.hud.style.expandedDetailed"
        }
    }

    var symbolName: String {
        switch self {
        case .standard:
            return "rectangle.and.text.magnifyingglass"
        case .compact:
            return "rectangle.compress.vertical"
        case .minimal:
            return "minus.rectangle"
        case .expandedCompact:
            return "square.split.2x1"
        case .expandedDetailed:
            return "square.split.1x2"
        }
    }
}
