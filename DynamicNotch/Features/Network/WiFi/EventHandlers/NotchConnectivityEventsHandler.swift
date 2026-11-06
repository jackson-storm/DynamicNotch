import SwiftUI

@MainActor
final class NotchConnectivityEventsHandler {
    private let notchViewModel: NotchViewModel
    private let bluetoothViewModel: BluetoothViewModel
    private let wifiViewModel: WifiViewModel
    private let vpnViewModel: VpnViewModel
    private let settingsViewModel: SettingsViewModel

    private var wifiTask: Task<Void, Never>?
    var wifiEventDelay: TimeInterval

    init(
        notchViewModel: NotchViewModel,
        bluetoothViewModel: BluetoothViewModel,
        wifiViewModel: WifiViewModel,
        vpnViewModel: VpnViewModel,
        settingsViewModel: SettingsViewModel,
        wifiEventDelay: TimeInterval = 5.0
    ) {
        self.notchViewModel = notchViewModel
        self.bluetoothViewModel = bluetoothViewModel
        self.wifiViewModel = wifiViewModel
        self.vpnViewModel = vpnViewModel
        self.settingsViewModel = settingsViewModel
        self.wifiEventDelay = wifiEventDelay
    }

    func cancelPendingWifiEvents() {
        wifiTask?.cancel()
        wifiTask = nil
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
        wifiTask?.cancel()
        wifiTask = Task { @MainActor [weak self] in
            if let delay = self?.wifiEventDelay, delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            guard let self, !Task.isCancelled else { return }

            if event == .noInternetConnection && self.wifiViewModel.isInternetAvailable {
                return
            }

            self.executeWifiEvent(event)
        }
    }

    private func executeWifiEvent(_ event: WifiEvent) {
        switch event {
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
                    HotspotActiveContent(
                        settingsViewModel: settingsViewModel,
                        wifiViewModel: wifiViewModel
                    )
                )
            )

        case .hotspotHide:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Wifi.hotspot.id))
        }
    }

    func handleVpn(_ event: VpnEvent) {
        switch event {
        case .vpnConnected:
            guard settingsViewModel.isLiveActivityEnabled(.vpn) else { return }
            guard !settingsViewModel.isVpnSettingsTabActive else { return }
            notchViewModel.send(
                .showLiveActivity(
                    VpnActiveNotchContent(
                        vpnViewModel: vpnViewModel,
                        notchViewModel: notchViewModel
                    )
                )
            )
        case .vpnDisconnected:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Vpn.vpn.id))
        }
    }
}
