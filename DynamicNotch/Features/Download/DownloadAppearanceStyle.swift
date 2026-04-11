import SwiftUI

enum DownloadAppearanceStyle: String, CaseIterable {
    case minimal
    case detailed

    var title: LocalizedStringKey {
        switch self {
        case .minimal:
            return "Minimal"
        case .detailed:
            return "Detailed"
        }
    }

    static func resolved(_ rawValue: String?) -> DownloadAppearanceStyle {
        switch rawValue {
        case DownloadAppearanceStyle.detailed.rawValue:
            return .detailed
        case "compact":
            return .detailed
        default:
            return .minimal
        }
    }
}
