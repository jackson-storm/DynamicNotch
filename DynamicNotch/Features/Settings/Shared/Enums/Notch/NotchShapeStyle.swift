import SwiftUI

enum NotchShapeStyle: String, CaseIterable {
    case capsule
    case notch

    var title: LocalizedStringKey {
        switch self {
        case .capsule:
            return "settings.notch.shapeStyle.capsule"
        case .notch:
            return "settings.notch.shapeStyle.notch"
        }
    }

    var symbolName: String {
        switch self {
        case .capsule:
            return "capsule.fill"
        case .notch:
            return "rectangle.topthird.inset.filled"
        }
    }

    static func resolved(_ rawValue: String?) -> NotchShapeStyle {
        guard let rawValue, let style = NotchShapeStyle(rawValue: rawValue) else {
            return .capsule
        }
        return style
    }
}
