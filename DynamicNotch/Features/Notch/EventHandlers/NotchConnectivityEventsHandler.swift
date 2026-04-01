import SwiftUI

@MainActor
final class NotchConnectivityEventsHandler {
    private let notchViewModel: NotchViewModel
    private let bluetoothViewModel: BluetoothViewModel
    private let networkViewModel: NetworkViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        bluetoothViewModel: BluetoothViewModel,
        networkViewModel: NetworkViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.bluetoothViewModel = bluetoothViewModel
        self.networkViewModel = networkViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
    }

    func handleBluetooth(_ event: BluetoothEvent) {
        switch event {
        case .connected:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.bluetooth) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    BluetoothConnectedNotchContent(bluetoothViewModel: bluetoothViewModel),
                    duration: generalSettingsViewModel.resolvedTemporaryActivityDuration(5)
                )
            )
        }
    }

    func handleNetwork(_ event: NetworkEvent) {
        switch event {
        case .wifiConnected:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.wifi) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    WifiConnectedNotchContent(),
                    duration: generalSettingsViewModel.resolvedTemporaryActivityDuration(3)
                )
            )

        case .vpnConnected:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.vpn) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    VpnConnectedNotchContent(networkViewModel: networkViewModel),
                    duration: generalSettingsViewModel.resolvedTemporaryActivityDuration(5)
                )
            )

        case .hotspotActive:
            guard generalSettingsViewModel.isLiveActivityEnabled(.hotspot) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    HotspotActiveContent(generalSettingsViewModel: generalSettingsViewModel)
                )
            )

        case .hotspotHide:
            notchViewModel.send(.hideLiveActivity(id: "hotspot.active"))
        }
    }
}
