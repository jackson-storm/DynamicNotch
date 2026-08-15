import SwiftUI

enum LockScreenMediaPanelBackgroundStyle: String, CaseIterable {
    case staticArtwork
    case black

    var title: LocalizedStringKey {
        switch self {
        case .staticArtwork:
            return "settings.lockScreen.mediaPanelBackgroundStyle.staticArtwork"
        case .black:
            return "settings.lockScreen.mediaPanelBackgroundStyle.black"
        }
    }
}
