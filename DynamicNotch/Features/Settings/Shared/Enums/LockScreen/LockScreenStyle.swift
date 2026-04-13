import SwiftUI

enum LockScreenStyle: String, CaseIterable {
    case enlarged
    case compact

    var title: LocalizedStringKey {
        switch self {
        case .enlarged:
            return "Enlarged"
        case .compact:
            return "Compact"
        }
    }
}
