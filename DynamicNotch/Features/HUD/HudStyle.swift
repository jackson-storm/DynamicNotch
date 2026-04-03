import SwiftUI

enum HudStyle: String, CaseIterable {
    case standard
    case compact
    case minimal

    var title: LocalizedStringKey {
        switch self {
        case .standard:
            return "settings.hud.style.standard"
        case .compact:
            return "settings.hud.style.compact"
        case .minimal:
            return "settings.hud.style.minimal"
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
        }
    }
}
