import SwiftUI

struct BatterySettingsView: View {
    @ObservedObject var batterySettings: BatterySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            batteryActivity
            batteryAppearance
        }
    }
    
    private var batteryActivity: some View {
        SettingsCard(
            title: "Battery activity",
            subtitle: "Control charging, low battery, and full battery notifications."
        ) {
            SettingsToggleRow(
                title: "Charging",
                description: "Show a temporary activity when your Mac starts charging.",
                systemImage: "bolt.fill",
                color: .green,
                isOn: $batterySettings.isChargerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.charger"
            )
            
            Divider()
            
            SettingsToggleRow(
                title: "Low Power",
                description: "Show a warning when Low Power Mode is enabled or the battery is critically low.",
                systemImage: "battery.25",
                color: .green,
                isOn: $batterySettings.isLowPowerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.lowPower"
            )
            
            Divider()
            
            SettingsToggleRow(
                title: "Fully Charged",
                description: "Show a temporary activity when the battery reaches full charge.",
                systemImage: "battery.100",
                color: .green,
                isOn: $batterySettings.isFullPowerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.fullPower"
            )
        }
    }
    
    private var batteryAppearance: some View {
        SettingsCard(
            title: "Battery appearance",
            subtitle: "Preview the battery notch and adjust its accent stroke."
        ) {
            NotchPreview(
                width: 340,
                height: 120,
                topCornerRadius: 22,
                bottomCornerRadius: 40,
                showsStroke: appearanceSettings.isShowNotchStrokeEnabled,
                strokeColor: batterySettings.isBatteryDefaultStrokeEnabled ?
                    .white.opacity(0.2) :
                        .red.opacity(0.3),
                strokeWidth: CGFloat(appearanceSettings.notchStrokeWidth)
            ) {
                LowPowerPreviewNotchView()
            }
            
            SettingsToggleRow(
                title: "Use default stroke color",
                description: "Use the default notch stroke color instead of the battery accent colors.",
                systemImage: "paintbrush.pointed.fill",
                color: .indigo,
                isOn: $batterySettings.isBatteryDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.battery.defaultStroke"
            )
        }
    }
}
