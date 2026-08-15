import SwiftUI

enum DownloadProgressIndicatorStyle: String, CaseIterable {
    case percent
    case circle

    var title: LocalizedStringKey {
        switch self {
        case .percent:
            return "settings.downloads.progressIndicatorStyle.percent"
        case .circle:
            return "settings.downloads.progressIndicatorStyle.circle"
        }
    }

    static func resolved(_ rawValue: String?) -> DownloadProgressIndicatorStyle {
        switch rawValue {
        case DownloadProgressIndicatorStyle.circle.rawValue:
            return .circle
        case "bar":
            return .percent
        default:
            return .percent
        }
    }
}
