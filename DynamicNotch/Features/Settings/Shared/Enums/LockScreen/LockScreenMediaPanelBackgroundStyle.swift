import SwiftUI

enum LockScreenMediaPanelBackgroundStyle: String, CaseIterable {
    case wallpaper
    case animatedArtwork
    case staticArtwork
    case black

    var title: LocalizedStringKey {
        switch self {
        case .wallpaper:
            return "Current wallpaper"
        case .animatedArtwork:
            return "Animated background"
        case .staticArtwork:
            return "Static background"
        case .black:
            return "Black background"
        }
    }
}
