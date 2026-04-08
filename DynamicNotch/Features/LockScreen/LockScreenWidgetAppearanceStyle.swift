import SwiftUI

enum LockScreenWidgetAppearanceStyle: String, CaseIterable {
    case ultraThinMaterial
    case ultraThickMaterial
    case liquidGlass

    static var availableOptions: [Self] {
        if #available(macOS 26.0, *) {
            return Array(allCases)
        }

        return [.ultraThinMaterial, .ultraThickMaterial]
    }

    var title: LocalizedStringKey {
        switch self {
        case .ultraThinMaterial:
            return "Soft"
        case .ultraThickMaterial:
            return "Solid"
        case .liquidGlass:
            return "Liquid Glass"
        }
    }

    var isSupportedOnCurrentSystem: Bool {
        switch self {
        case .ultraThinMaterial, .ultraThickMaterial:
            return true
        case .liquidGlass:
            if #available(macOS 26.0, *) {
                return true
            }

            return false
        }
    }
}
