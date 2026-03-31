import SwiftUI

@MainActor
final class NotchSystemEventsHandler {
    private let notchViewModel: NotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
    }

    func handleNotchSize(_ event: NotchSizeEvent) {
        switch event {
        case .width:
            notchViewModel.send(
                .showTemporaryNotification(
                    NotchSizeWidthNotchContent(generalSettingsViewModel: generalSettingsViewModel),
                    duration: 2
                )
            )

        case .height:
            notchViewModel.send(
                .showTemporaryNotification(
                    NotchSizeHeightNotchContent(generalSettingsViewModel: generalSettingsViewModel),
                    duration: 2
                )
            )
        }
    }
}

@MainActor
final class NotchFocusEventsHandler {
    private let notchViewModel: NotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
    }

    func handle(_ event: FocusEvent) {
        switch event {
        case .FocusOn:
            guard generalSettingsViewModel.isLiveActivityEnabled(.focus) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    FocusOnNotchContent(generalSettingsViewModel: generalSettingsViewModel)
                )
            )

        case .FocusOff:
            notchViewModel.send(.hideLiveActivity(id: "focus.on"))
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.focusOff) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    FocusOffNotchContent(generalSettingsViewModel: generalSettingsViewModel),
                    duration: 3
                )
            )
        }
    }
}

@MainActor
final class NotchHUDEventsHandler {
    private let notchViewModel: NotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
    }

    func handle(_ event: HudEvent) {
        switch event {
        case .display(let level):
            guard generalSettingsViewModel.isHUDEnabled(.brightness) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(kind: .brightness, level: level),
                    duration: 2
                )
            )

        case .keyboard(let level):
            guard generalSettingsViewModel.isHUDEnabled(.keyboard) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(kind: .keyboard, level: level),
                    duration: 2
                )
            )

        case .volume(let level):
            guard generalSettingsViewModel.isHUDEnabled(.volume) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(kind: .volume, level: level),
                    duration: 2
                )
            )
        }
    }
}

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
                    duration: 5
                )
            )
        }
    }

    func handleNetwork(_ event: NetworkEvent) {
        switch event {
        case .wifiConnected:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.wifi) else { return }
            notchViewModel.send(.showTemporaryNotification(WifiConnectedNotchContent(), duration: 3))

        case .vpnConnected:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.vpn) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    VpnConnectedNotchContent(networkViewModel: networkViewModel),
                    duration: 5
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

@MainActor
final class NotchPowerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let powerService: PowerService
    private let generalSettingsViewModel: GeneralSettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        powerService: PowerService,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.powerService = powerService
        self.generalSettingsViewModel = generalSettingsViewModel
    }

    func handle(_ event: PowerEvent) {
        switch event {
        case .charger:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.charger) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    ChargerNotchContent(
                        powerService: powerService,
                        generalSettingsViewModel: generalSettingsViewModel
                    ),
                    duration: 4
                )
            )

        case .lowPower:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.lowPower) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    LowPowerNotchContent(
                        powerService: powerService,
                        generalSettingsViewModel: generalSettingsViewModel
                    ),
                    duration: 4
                )
            )

        case .fullPower:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.fullPower) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    FullPowerNotchContent(
                        powerService: powerService,
                        generalSettingsViewModel: generalSettingsViewModel
                    ),
                    duration: 4
                )
            )
        }
    }
}

@MainActor
final class NotchMediaEventsHandler {
    private let notchViewModel: NotchViewModel
    private let downloadViewModel: DownloadViewModel
    private let airDropViewModel: AirDropNotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private var deferredNowPlayingHideWhileExpanded = false

    init(
        notchViewModel: NotchViewModel,
        downloadViewModel: DownloadViewModel,
        airDropViewModel: AirDropNotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.downloadViewModel = downloadViewModel
        self.airDropViewModel = airDropViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
    }

    func handleDownload(_ event: DownloadEvent) {
        switch event {
        case .started:
            guard generalSettingsViewModel.isLiveActivityEnabled(.downloads) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    DownloadNotchContent(
                        downloadViewModel: downloadViewModel,
                        generalSettingsViewModel: generalSettingsViewModel
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: "download.active"))
        }
    }

    func handleAirDrop(_ event: AirDropEvent) {
        switch event {
        case .dragStarted:
            guard generalSettingsViewModel.isLiveActivityEnabled(.airDrop) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    AirDropNotchContent(
                        airDropViewModel: airDropViewModel,
                        generalSettingsViewModel: generalSettingsViewModel
                    )
                )
            )

        case .dragEnded, .dropped:
            notchViewModel.send(.hideLiveActivity(id: "airdrop"))
        }
    }

    func handleNowPlaying(_ event: NowPlayingEvent) {
        switch event {
        case .started:
            deferredNowPlayingHideWhileExpanded = false
            guard generalSettingsViewModel.isLiveActivityEnabled(.nowPlaying) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    NowPlayingNotchContent(nowPlayingViewModel: nowPlayingViewModel)
                )
            )

        case .stopped:
            if isExpandedNowPlayingVisible {
                deferredNowPlayingHideWhileExpanded = true
                return
            }

            deferredNowPlayingHideWhileExpanded = false
            notchViewModel.send(.hideLiveActivity(id: "nowPlaying"))
        }
    }

    func cancelDeferredNowPlayingHide() {
        deferredNowPlayingHideWhileExpanded = false
    }

    func handleExpansionChange(isExpanded: Bool) {
        guard deferredNowPlayingHideWhileExpanded else { return }
        guard !isExpanded else { return }
        guard nowPlayingViewModel.hasActiveSession == false else {
            deferredNowPlayingHideWhileExpanded = false
            return
        }

        deferredNowPlayingHideWhileExpanded = false
        notchViewModel.send(.hideLiveActivity(id: "nowPlaying"))
    }

    private var isExpandedNowPlayingVisible: Bool {
        notchViewModel.notchModel.liveActivityContent?.id == "nowPlaying" &&
        notchViewModel.notchModel.isLiveActivityExpanded
    }
}
