import SwiftUI

enum BluetoothAppearanceStyle: String, CaseIterable {
    case device
    case detailed

    var title: LocalizedStringKey {
        switch self {
        case .device:
            return "Device"
        case .detailed:
            return "Detailed"
        }
    }

    var supportsBatteryPresentation: Bool {
        true
    }

    static func resolved(_ rawValue: String?) -> BluetoothAppearanceStyle {
        switch rawValue {
        case "compact":
            return .device
        case BluetoothAppearanceStyle.device.rawValue:
            return .device
        case BluetoothAppearanceStyle.detailed.rawValue:
            return .detailed
        default:
            return .device
        }
    }
}
