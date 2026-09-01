import SwiftUI

enum HotspotAppearanceStyle: String, CaseIterable {
    case minimal
    case detailed
    case battery

    var title: LocalizedStringKey {
        switch self {
        case .minimal:
            return "settings.wifi.hotspotAppearanceStyle.minimal"
        case .detailed:
            return "settings.wifi.hotspotAppearanceStyle.detailed"
        case .battery:
            return "settings.wifi.hotspotAppearanceStyle.battery"
        }
    }
}
