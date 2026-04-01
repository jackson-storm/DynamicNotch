enum HudStyle: String, CaseIterable {
    case standard
    case compact
    case minimal

    var title: String {
        switch self {
        case .standard:
            return "Standard"
        case .compact:
            return "Compact"
        case .minimal:
            return "Minimal"
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
