import SwiftUI

enum VPNAppearanceStyle: String, CaseIterable {
    case compact
    case detailed

    var title: LocalizedStringKey {
        switch self {
        case .compact:
            return "Compact"
        case .detailed:
            return "Detailed"
        }
    }
}
