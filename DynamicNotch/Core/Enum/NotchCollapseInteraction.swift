import SwiftUI

enum NotchCollapseInteraction: String, CaseIterable {
    case click
    case hoverLeaves

    var title: LocalizedStringKey {
        switch self {
        case .click:
            return "Click"
        case .hoverLeaves:
            return "Cursor leaves"
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
