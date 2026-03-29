import SwiftUI

struct BatterySettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Battery activity",
                subtitle: "Short-lived charging and power state notifications."
            ) {
                VStack {
                    SettingsToggleRow(
                        title: "Charging",
                        description: "Show a temporary card when power is connected.",
                        systemImage: "bolt.fill",
                        color: .green,
                        isOn: $generalSettingsViewModel.isChargerTemporaryActivityEnabled,
                        accessibilityIdentifier: "settings.activities.temporary.charger"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Low Power",
                        description: "Warn when Low Power Mode or a critical battery level is detected.",
                        systemImage: "battery.25",
                        color: .green,
                        isOn: $generalSettingsViewModel.isLowPowerTemporaryActivityEnabled,
                        accessibilityIdentifier: "settings.activities.temporary.lowPower"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Fully Charged",
                        description: "Celebrate a full battery with a brief notification.",
                        systemImage: "battery.100",
                        color: .green,
                        isOn: $generalSettingsViewModel.isFullPowerTemporaryActivityEnabled,
                        accessibilityIdentifier: "settings.activities.temporary.fullPower"
                    )
                }
            }
        }
    }
}
