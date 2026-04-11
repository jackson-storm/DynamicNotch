import SwiftUI

struct BluetoothSettingsView: View {
    @ObservedObject var settings: ConnectivitySettingsStore

    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }

    var body: some View {
        SettingsPageScrollView {
            bluetoothActivity
            bluetoothDuration
        }
    }

    private var bluetoothActivity: some View {
        SettingsCard(
            title: "Bluetooth activity",
            subtitle: "Show a short notification when Bluetooth accessories connect."
        ) {
            SettingsToggleRow(
                title: "Bluetooth temporary activity",
                description: "Show a temporary activity when a Bluetooth accessory connects.",
                imageName: "bluetooth.white",
                color: .blue,
                isOn: $settings.isBluetoothTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.bluetooth"
            )
        }
    }

    private var bluetoothDuration: some View {
        SettingsCard(
            title: "Bluetooth duration",
            subtitle: "Control how long the Bluetooth notification stays visible."
        ) {
            SettingsSliderRow(
                title: "Bluetooth duration",
                description: "Choose how long the Bluetooth connection notification stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.bluetooth.duration",
                value: Binding(
                    get: { Double(settings.bluetoothTemporaryActivityDuration) },
                    set: { settings.bluetoothTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isBluetoothTemporaryActivityEnabled)
            .opacity(settings.isBluetoothTemporaryActivityEnabled ? 1 : 0.5)
        }
    }
}
