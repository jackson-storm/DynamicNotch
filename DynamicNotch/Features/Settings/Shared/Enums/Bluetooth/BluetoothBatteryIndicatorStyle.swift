import SwiftUI

enum BluetoothBatteryIndicatorStyle: String, CaseIterable {
    case percent
    case circle

    var title: LocalizedStringKey {
        switch self {
        case .percent:
            return "settings.bluetooth.batteryIndicatorStyle.percent"
        case .circle:
            return "settings.bluetooth.batteryIndicatorStyle.circle"
        }
    }
}
