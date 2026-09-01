import SwiftUI

enum BatteryNotificationStyle: String, CaseIterable {
    case standard
    case compact

    var title: LocalizedStringKey {
        switch self {
        case .standard:
            return "settings.battery.notificationStyle.standard"
        case .compact:
            return "settings.battery.notificationStyle.compact"
        }
    }
}
