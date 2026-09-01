import SwiftUI

enum HudIndicatorStyle: String, CaseIterable {
    case bar
    case circle

    var title: LocalizedStringKey {
        switch self {
        case .bar:
            return "settings.hud.indicatorStyle.bar"
        case .circle:
            return "settings.hud.indicatorStyle.circle"
        }
    }

    var symbolName: String {
        switch self {
        case .bar:
            return "rectangle.lefthalf.filled"
        case .circle:
            return "circle.dotted.circle"
        }
    }
}

enum HudIndicatorTintStyle: String, CaseIterable {
    case plainWhite
    case levelColor
    case accentColor

    var title: LocalizedStringKey {
        switch self {
        case .plainWhite:
            return "settings.hud.indicatorTintStyle.plainWhite"
        case .levelColor:
            return "settings.hud.indicatorTintStyle.levelColor"
        case .accentColor:
            return "settings.hud.indicatorTintStyle.accentColor"
        }
    }
}
