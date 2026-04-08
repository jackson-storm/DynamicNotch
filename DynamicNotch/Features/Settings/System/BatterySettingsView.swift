import SwiftUI

struct BatterySettingsView: View {
    @ObservedObject var batterySettings: BatterySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            batteryActivity
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
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Low Power",
                description: "Show a warning when Low Power Mode is enabled or the battery is critically low.",
                systemImage: "battery.25",
                color: .green,
                isOn: $batterySettings.isLowPowerTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.lowPower"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
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
}
