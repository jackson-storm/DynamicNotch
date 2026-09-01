import SwiftUI

enum FocusAppearanceStyle: String, CaseIterable {
    case standard
    case iconsOnly

    var title: LocalizedStringKey {
        switch self {
        case .standard:
            return "settings.focus.appearanceStyle.standard"
        case .iconsOnly:
            return "settings.focus.appearanceStyle.iconsOnly"
        }
    }

    static func resolved(_ rawValue: String?) -> FocusAppearanceStyle {
        FocusAppearanceStyle(rawValue: rawValue ?? FocusAppearanceStyle.iconsOnly.rawValue) ?? .iconsOnly
    }
}
