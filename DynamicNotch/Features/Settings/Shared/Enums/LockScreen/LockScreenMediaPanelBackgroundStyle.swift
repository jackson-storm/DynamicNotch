import SwiftUI

enum LockScreenMediaPanelBackgroundStyle: String, CaseIterable {
    case staticArtwork
    case black

    var title: LocalizedStringKey {
        switch self {
        case .staticArtwork:
            return "Static background"
        case .black:
            return "Black background"
        }
    }
}
