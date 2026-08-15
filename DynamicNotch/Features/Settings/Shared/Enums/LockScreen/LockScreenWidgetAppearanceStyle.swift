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
            return "settings.lockScreen.widgetAppearanceStyle.soft"
        case .ultraThickMaterial:
            return "settings.lockScreen.widgetAppearanceStyle.solid"
        case .liquidGlass:
            return "settings.lockScreen.widgetAppearanceStyle.liquidGlass"
        }
    }

    var isSupportedOnCurrentSystem: Bool {
        return true
    }
}
