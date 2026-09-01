import SwiftUI

enum LockScreenMediaPanelBackgroundStyle: String, CaseIterable {
    case animatedArtwork
    case staticArtwork
    case black

    var title: LocalizedStringKey {
        switch self {
        case .animatedArtwork:
            return "settings.lockScreen.mediaPanelBackgroundStyle.animatedArtwork"
        case .staticArtwork:
            return "settings.lockScreen.mediaPanelBackgroundStyle.staticArtwork"
        case .black:
            return "settings.lockScreen.mediaPanelBackgroundStyle.black"
        }
    }
}
