import SwiftUI

enum LockScreenWidgetAppearanceStyle: String, CaseIterable {
    case ultraThinMaterial
    case ultraThickMaterial
    case liquidGlass

    static var availableOptions: [Self] {
        return Array(allCases)
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
        return true
    }
}
