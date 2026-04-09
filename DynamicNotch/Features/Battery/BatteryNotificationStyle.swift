import SwiftUI

enum BatteryNotificationStyle: String, CaseIterable {
    case standard
    case compact

    var title: LocalizedStringKey {
        switch self {
        case .standard:
            return "Standard"
        case .compact:
            return "Compact"
        }
    }
}
