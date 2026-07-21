import SwiftUI

enum LockScreenWidgetAppearanceStyle: String, CaseIterable {
    case ultraThinMaterial
    case ultraThickMaterial

    static var availableOptions: [Self] {
        return Array(allCases)
    }

    var title: LocalizedStringKey {
        switch self {
        case .ultraThinMaterial:
            return "Soft"
        case .ultraThickMaterial:
            return "Solid"
        }
    }

    var isSupportedOnCurrentSystem: Bool {
        return true
    }
}
