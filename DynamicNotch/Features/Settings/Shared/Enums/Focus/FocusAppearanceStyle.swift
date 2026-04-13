import SwiftUI

enum FocusAppearanceStyle: String, CaseIterable {
    case standard
    case iconsOnly

    var title: LocalizedStringKey {
        switch self {
        case .standard:
            return "Default"
        case .iconsOnly:
            return "Icons Only"
        }
    }

    static func resolved(_ rawValue: String?) -> FocusAppearanceStyle {
        FocusAppearanceStyle(rawValue: rawValue ?? FocusAppearanceStyle.standard.rawValue) ?? .standard
    }
}
