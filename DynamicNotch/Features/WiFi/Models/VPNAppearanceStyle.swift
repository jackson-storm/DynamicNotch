import SwiftUI

enum VPNAppearanceStyle: String, CaseIterable {
    case compact
    case detailed

    var title: LocalizedStringKey {
        switch self {
        case .compact:
            return "settings.vpn.appearanceStyle.compact"
        case .detailed:
            return "settings.vpn.appearanceStyle.detailed"
        }
    }
}
