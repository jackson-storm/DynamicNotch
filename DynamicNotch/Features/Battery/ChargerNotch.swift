import SwiftUI

struct ChargerNotchContent: NotchContentProtocol {
    let id = "battery.charger"
    let powerService: PowerService
    let settingsViewModel: SettingsViewModel
    
    var offsetXTransition: CGFloat { -90 }
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
            .white.opacity(0.2) : (powerService.isLowPowerMode ? .yellow.opacity(0.3) : .green.opacity(0.3))
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth + 180, height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(ChargerNotchView(powerService: powerService))
    }
}

struct ChargerNotchView: View {
    @ObservedObject var powerService: PowerService
    
    private var batteryColor: Color {
        if powerService.isLowPowerMode {
            return .yellow
        } else if powerService.batteryLevel <= 20 {
            return .red
        } else {
            return .green
        }
    }
    
    var body: some View {
        BatteryCompactStatusView(
            title: "Charging",
            batteryLevel: powerService.batteryLevel,
            tint: batteryColor
        )
    }
}

struct ChargerPreviewNotchView: View {
    @StateObject private var powerService = PowerService.settingsPreview(
        onACPower: true,
        batteryLevel: 73,
        isCharging: true,
        isLowPowerMode: false
    )

    var body: some View {
        ChargerNotchView(powerService: powerService)
    }
}
