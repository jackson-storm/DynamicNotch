import SwiftUI

enum BluetoothAppearanceStyle: String, CaseIterable {
    case compact
    case detailed

    var title: LocalizedStringKey {
        switch self {
        case .compact:
            return "Compact"
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
