import SwiftUI

@MainActor
final class NotchConnectivityEventsHandler {
    private let notchViewModel: NotchViewModel
    private let bluetoothViewModel: BluetoothViewModel
    private let networkViewModel: NetworkViewModel
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        bluetoothViewModel: BluetoothViewModel,
        networkViewModel: NetworkViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.bluetoothViewModel = bluetoothViewModel
        self.networkViewModel = networkViewModel
        self.settingsViewModel = settingsViewModel
    }

    func handleBluetooth(_ event: BluetoothEvent) {
        switch event {
        case .connected:
            guard settingsViewModel.isTemporaryActivityEnabled(.bluetooth) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    BluetoothConnectedNotchContent(bluetoothViewModel: bluetoothViewModel),
                    duration: settingsViewModel.resolvedTemporaryActivityDuration(5)
                )
            )
        }
    }

    func handleNetwork(_ event: NetworkEvent) {
        switch event {
        case .wifiConnected:
            guard settingsViewModel.isTemporaryActivityEnabled(.wifi) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    WifiConnectedNotchContent(),
                    duration: settingsViewModel.resolvedTemporaryActivityDuration(3)
                )
            )

        case .vpnConnected:
            guard settingsViewModel.isTemporaryActivityEnabled(.vpn) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    VpnConnectedNotchContent(networkViewModel: networkViewModel),
                    duration: settingsViewModel.resolvedTemporaryActivityDuration(5)
                )
            )

        case .hotspotActive:
            guard settingsViewModel.isLiveActivityEnabled(.hotspot) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    HotspotActiveContent(settingsViewModel: settingsViewModel)
                )
            )

        case .hotspotHide:
            notchViewModel.send(.hideLiveActivity(id: "hotspot.active"))
        }
    }
}
