import SwiftUI

enum HudIndicatorStyle: String, CaseIterable {
    case bar
    case circle

    var title: LocalizedStringKey {
        switch self {
        case .bar:
            return "Bar"
        case .circle:
            return "Circle"
        }
    }

    var symbolName: String {
        switch self {
        case .bar:
            return "rectangle.lefthalf.filled"
        case .circle:
            return "circle.dotted.circle"
        }
    }
}
