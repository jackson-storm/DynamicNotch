import SwiftUI

enum LockScreenStyle: String, CaseIterable {
    case enlarged
    case compact

    var title: LocalizedStringKey {
        switch self {
        case .enlarged:
            return "settings.lockScreen.style.enlarged"
        case .compact:
            return "settings.lockScreen.style.compact"
        }
    }
}
