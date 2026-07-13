import SwiftUI

enum NotchExpandInteraction: String, CaseIterable {
    case click
    case pressAndHold
    case hover

    var title: LocalizedStringKey {
        switch self {
        case .click:
            return "Click"
        case .pressAndHold:
            return "Press and hold"
        case .hover:
            return "Hover"
        }
    }

    static func resolved(_ rawValue: String?) -> NotchExpandInteraction {
        guard let rawValue,
              let interaction = NotchExpandInteraction(rawValue: rawValue) else {
            return .pressAndHold
        }

        return interaction
    }
}
