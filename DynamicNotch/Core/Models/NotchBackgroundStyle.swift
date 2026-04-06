import SwiftUI

enum NotchBackgroundStyle: String, CaseIterable {
    case black
    case ultraThickMaterial

    var title: LocalizedStringKey {
        switch self {
        case .black:
            return "Black"
        case .ultraThickMaterial:
            return "Material"
        }
    }

    var symbolName: String {
        switch self {
        case .black:
            return "circle.fill"
        case .ultraThickMaterial:
            return "square.stack.3d.up.fill"
        }
    }

    static func resolved(_ rawValue: String?) -> NotchBackgroundStyle {
        guard let rawValue, let style = NotchBackgroundStyle(rawValue: rawValue) else {
            return .black
        }
        return style
    }
}
