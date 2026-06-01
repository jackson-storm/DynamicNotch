import SwiftUI

enum BluetoothEvent: Equatable {
    case connected
}

struct BluetoothConnectedNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Network.bluetooth.id
    let bluetoothViewModel: BluetoothViewModel
    let settings: ConnectivitySettingsStore
    let applicationSettings: ApplicationSettingsStore
    
    var priority: Int { NotchContentRegistry.Network.bluetooth.priority }
    
    var strokeColor: Color {
        guard settings.bluetoothAppearanceStyle.supportsBatteryPresentation,
              settings.isBluetoothBatteryStrokeEnabled,
              applicationSettings.isDefaultActivityStrokeEnabled == false,
              let batteryLevel = bluetoothViewModel.batteryLevel else {
            return .white.opacity(0.2)
        }
        return batteryStrokeColor(for: batteryLevel).opacity(0.3)
    }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (
            top: settings.bluetoothAppearanceStyle == .compact ? baseRadius - 4 : 20,
            bottom: settings.bluetoothAppearanceStyle == .compact ? baseRadius : 38
        )
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: CGFloat

        switch settings.bluetoothAppearanceStyle {
        case .compact:
            width = settings.bluetoothBatteryIndicatorStyle == .circle ? 80 : 90
        case .detailed:
            width = settings.bluetoothBatteryIndicatorStyle == .circle ? 145 : 145
        }
        return .init(width: baseWidth + CGFloat(width), height: settings.bluetoothAppearanceStyle == .compact ? baseHeight : 95)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: CGFloat

        switch settings.bluetoothAppearanceStyle {
        case .compact:
            width = settings.bluetoothBatteryIndicatorStyle == .circle ? 70 : 90
        case .detailed:
            width = settings.bluetoothBatteryIndicatorStyle == .circle ? 175 : 145
        }
        return .init(width: baseWidth + CGFloat(width), height: settings.bluetoothAppearanceStyle == .compact ? baseHeight : 75)
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
