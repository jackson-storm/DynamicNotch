import SwiftUI

struct BluetoothSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Bluetooth activity",
                subtitle: "Short-lived Bluetooth connection feedback for accessories and audio devices."
            ) {
                SettingsToggleRow(
                    title: "Bluetooth temporary activity",
                    description: "Show a card when a Bluetooth accessory connects.",
                    systemImage: "headphones",
                    color: .blue,
                    isOn: $generalSettingsViewModel.isBluetoothTemporaryActivityEnabled,
                    accessibilityIdentifier: "settings.activities.temporary.bluetooth"
                )
            }
        }
    }
}
