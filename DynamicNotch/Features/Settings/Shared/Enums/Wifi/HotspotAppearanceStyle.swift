import SwiftUI

enum HotspotAppearanceStyle: String, CaseIterable {
    case minimal
    case detailed

    var title: LocalizedStringKey {
        switch self {
        case .minimal:
            return "settings.wifi.hotspotAppearanceStyle.minimal"
        case .detailed:
            return "settings.wifi.hotspotAppearanceStyle.detailed"
        }
    }
}
