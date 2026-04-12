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

    func resolvedColor() -> Color? {
        switch self {
        case .neutral:
            return nil
        case .accent:
            return .accentColor
        }
    }
}
