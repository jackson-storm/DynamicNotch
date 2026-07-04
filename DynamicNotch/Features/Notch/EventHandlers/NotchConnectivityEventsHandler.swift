import SwiftUI

@MainActor
final class NotchConnectivityEventsHandler {
    private let notchViewModel: NotchViewModel
    private let bluetoothViewModel: BluetoothViewModel
    private let wifiViewModel: WifiViewModel
    private let vpnViewModel: VpnViewModel
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        bluetoothViewModel: BluetoothViewModel,
        wifiViewModel: WifiViewModel,
        vpnViewModel: VpnViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.bluetoothViewModel = bluetoothViewModel
        self.wifiViewModel = wifiViewModel
        self.vpnViewModel = vpnViewModel
        self.settingsViewModel = settingsViewModel
    }

    func handleBluetooth(_ event: BluetoothEvent) {
        switch event {
        case .connected:
            guard settingsViewModel.isTemporaryActivityEnabled(.bluetooth) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    BluetoothConnectedNotchContent(
                        bluetoothViewModel: bluetoothViewModel,
                        settings: settingsViewModel.connectivity,
                        applicationSettings: settingsViewModel.application
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .bluetooth)
                )
            )
        }
    }

    func handleWifi(_ event: WifiEvent) {
        switch event {
        case .wifiConnected:
            guard settingsViewModel.isTemporaryActivityEnabled(.wifi) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    WifiConnectedNotchContent(
                        wifiViewModel: wifiViewModel
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .wifi)
                )
            )

        case .noInternetConnection:
            guard settingsViewModel.connectivity.isNoInternetTemporaryActivityEnabled else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    NoInternetConnectionContent(
                        onDismiss: { [weak self] in
                            self?.notchViewModel.hideTemporaryNotification()
                        }
                    ),
                    duration: .infinity
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
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Wifi.hotspot.id))
        }
    }

    func handleVpn(_ event: VpnEvent) {
        switch event {
        case .vpnConnected:
            guard settingsViewModel.isTemporaryActivityEnabled(.vpn) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    VpnConnectedNotchContent(
                        vpnViewModel: vpnViewModel,
                        settings: settingsViewModel.connectivity
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .vpn)
                )
            )
        case .vpnDisconnected:
            guard settingsViewModel.isTemporaryActivityEnabled(.vpnDisconnected) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    VpnDisconnectedNotchContent(
                        vpnViewModel: vpnViewModel,
                        settings: settingsViewModel.connectivity
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .vpnDisconnected)
                )
            )
        }
    }
}
