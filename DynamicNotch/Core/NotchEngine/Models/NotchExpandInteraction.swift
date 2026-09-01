import SwiftUI

enum NotchExpandInteraction: String, CaseIterable {
    case click
    case pressAndHold
    case hover

    var title: LocalizedStringKey {
        switch self {
        case .click:
            return "settings.notch.gestures.expand.click"
        case .pressAndHold:
            return "settings.notch.gestures.expand.pressAndHold"
        case .hover:
            return "settings.notch.gestures.expand.hover"
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
