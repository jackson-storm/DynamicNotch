import SwiftUI

enum LockScreenWidgetTintStyle: String, CaseIterable {
    case neutral
    case accent

    var title: LocalizedStringKey {
        switch self {
        case .neutral:
            return "settings.lockScreen.widgetTintStyle.neutral"
        case .accent:
            return "settings.lockScreen.widgetTintStyle.accent"
        }
    }

    func resolvedColor() -> Color? {
        switch self {
        case .neutral:
            return nil
        case .accent:
            return .accentColor
        }
    }
}
