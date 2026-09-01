import SwiftUI

enum NotchCollapseInteraction: String, CaseIterable {
    case click
    case hoverLeaves

    var title: LocalizedStringKey {
        switch self {
        case .click:
            return "settings.notch.gestures.collapse.click"
        case .hoverLeaves:
            return "settings.notch.gestures.collapse.hoverLeaves"
        }
    }

    static func resolved(_ rawValue: String?) -> NotchCollapseInteraction {
        guard let rawValue,
              let interaction = NotchCollapseInteraction(rawValue: rawValue) else {
            return .click
        }

        return interaction
    }
}
