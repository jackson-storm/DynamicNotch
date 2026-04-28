import SwiftUI

enum LockScreenMediaPanelBackgroundStyle: String, CaseIterable {
    case animatedArtwork
    case staticArtwork
    case black

    var title: LocalizedStringKey {
        switch self {
        case .animatedArtwork:
            return "Animated background"
        case .staticArtwork:
            return "Static background"
        case .black:
            return "Black background"
        }
    }
}
