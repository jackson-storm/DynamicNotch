import SwiftUI

enum BluetoothEvent: Equatable {
    case connected
}

struct BluetoothConnectedNotchContent: NotchContentProtocol {
    let id = "bluetooth.connected"
    let bluetoothViewModel: BluetoothViewModel
    let settings: ConnectivitySettingsStore
    let applicationSettings: ApplicationSettingsStore
    
    var offsetXTransition: CGFloat { -90 }
    
    var strokeColor: Color {
        guard settings.bluetoothAppearanceStyle.supportsBatteryPresentation,
              settings.isBluetoothBatteryStrokeEnabled,
              applicationSettings.isDefaultActivityStrokeEnabled == false,
              let batteryLevel = bluetoothViewModel.batteryLevel else {
            return .white.opacity(0.2)
        }
        return batteryStrokeColor(for: batteryLevel).opacity(0.3)
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: CGFloat

        switch settings.bluetoothAppearanceStyle {
        case .device:
            width = settings.bluetoothBatteryIndicatorStyle == .circle ? 80 : 90
        case .detailed:
            width = settings.bluetoothBatteryIndicatorStyle == .circle ? 180 : 180
        }
        return .init(width: baseWidth + CGFloat(width), height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            BluetoothConnectedNotchView(
                bluetoothViewModel: bluetoothViewModel,
                settings: settings,
                applicationSettings: applicationSettings
            )
        )
    }

    private func batteryStrokeColor(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
}
