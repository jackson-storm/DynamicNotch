import SwiftUI

struct BluetoothSettingsView: View {
    @ObservedObject var settings: ConnectivitySettingsStore

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Bluetooth activity",
                subtitle: "Show a short notification when Bluetooth accessories connect."
            ) {
                SettingsToggleRow(
                    title: "Bluetooth temporary activity",
                    description: "Show a temporary activity when a Bluetooth accessory connects.",
                    systemImage: "headphones",
                    color: .blue,
                    isOn: $settings.isBluetoothTemporaryActivityEnabled,
                    accessibilityIdentifier: "settings.activities.temporary.bluetooth"
                )
            }
        }
    }
}
