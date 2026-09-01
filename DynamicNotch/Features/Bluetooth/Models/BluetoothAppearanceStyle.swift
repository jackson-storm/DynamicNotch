import SwiftUI

enum BluetoothAppearanceStyle: String, CaseIterable {
    case compact
    case detailed

    var title: LocalizedStringKey {
        switch self {
        case .compact:
            return "settings.bluetooth.appearanceStyle.compact"
        case .detailed:
            return "settings.bluetooth.appearanceStyle.detailed"
        }
    }

    var supportsBatteryPresentation: Bool {
        true
    }

    static func resolved(_ rawValue: String?) -> BluetoothAppearanceStyle {
        switch rawValue {
        case "compact":
            return .compact
        case BluetoothAppearanceStyle.compact.rawValue:
            return .compact
        case BluetoothAppearanceStyle.detailed.rawValue:
            return .detailed
        default:
            return .compact
        }
    }
}
