import SwiftUI

enum LockScreenWidgetTintStyle: String, CaseIterable {
    case neutral
    case accent

    var title: LocalizedStringKey {
        switch self {
        case .neutral:
            return "Default"
        case .accent:
            return "Accent"
        }
    }

    func resolvedColor(appTint: AppTint) -> Color? {
        switch self {
        case .neutral:
            return nil
        case .accent:
            return appTint.color
        }
    }
}
