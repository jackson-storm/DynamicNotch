import SwiftUI

enum HotspotAppearanceStyle: String, CaseIterable {
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
}
