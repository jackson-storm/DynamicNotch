import SwiftUI

enum NotchBackgroundStyle: String, CaseIterable {
    case black

    static var availableOptions: [Self] {
        return Array(allCases)
    }

    var title: LocalizedStringKey {
        switch self {
        case .black:
            return "settings.notch.backgroundStyle.black"
        }
    }

    var symbolName: String {
        switch self {
        case .black:
            return "circle.fill"
        }
    }

    var isSupportedOnCurrentSystem: Bool {
        return true
    }

    static func resolved(_ rawValue: String?) -> NotchBackgroundStyle {
        guard let rawValue, let style = NotchBackgroundStyle(rawValue: rawValue) else {
            return .black
        }

        return style
    }
}
