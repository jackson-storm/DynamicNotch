import Foundation

@MainActor
final class AppContainer {
    let powerService = PowerService()
    let bluetoothViewModel = BluetoothViewModel()
    let networkViewModel = NetworkViewModel()
    let focusViewModel = FocusViewModel()
    let airDropViewModel = AirDropNotchViewModel()
    let generalSettingsViewModel = GeneralSettingsViewModel()

    let powerViewModel: PowerViewModel
    let downloadViewModel: DownloadViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let lockScreenManager: LockScreenManager

    lazy var hardwareHUDMonitor: HardwareHUDMonitor = {
        let monitor = HardwareHUDMonitor()
        monitor.onEvent = { [weak self] event in
            self?.notchEventCoordinator.handleHudEvent(event)
        }
        monitor.updateConfiguration(
            interceptVolume: generalSettingsViewModel.hud.isVolumeHUDEnabled,
            interceptBrightness: generalSettingsViewModel.hud.isBrightnessHUDEnabled
        )
        return monitor
    }()

    lazy var notchViewModel = NotchViewModel(settings: generalSettingsViewModel.application)
    lazy var airDropController = NotchAirDropController(airDropViewModel: airDropViewModel)

    lazy var notchEventCoordinator = NotchEventCoordinator(
        notchViewModel: notchViewModel,
        bluetoothViewModel: bluetoothViewModel,
        powerService: powerService,
        networkViewModel: networkViewModel,
        downloadViewModel: downloadViewModel,
        airDropViewModel: airDropViewModel,
        generalSettingsViewModel: generalSettingsViewModel,
        nowPlayingViewModel: nowPlayingViewModel,
        lockScreenManager: lockScreenManager
    )

    lazy var lockScreenPanelManager = LockScreenPanelManager(
        nowPlayingViewModel: nowPlayingViewModel,
        lockScreenManager: lockScreenManager,
        generalSettingsViewModel: generalSettingsViewModel
    )

    lazy var lockScreenLiveActivityWindowManager = LockScreenLiveActivityWindowManager(
        notchViewModel: notchViewModel,
        lockScreenManager: lockScreenManager,
        generalSettingsViewModel: generalSettingsViewModel
    )

    init(isRunningUITests: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing")) {
        self.powerViewModel = PowerViewModel(powerService: powerService)
        self.nowPlayingViewModel = NowPlayingViewModel(
            service: isRunningUITests ?
                InactiveNowPlayingService() :
                MediaRemoteNowPlayingService()
        )
        self.downloadViewModel = DownloadViewModel(
            monitor: isRunningUITests ?
                InactiveDownloadMonitor() :
                FolderFileDownloadMonitor()
        )
        self.lockScreenManager = LockScreenManager(
            service: isRunningUITests ?
                InactiveLockScreenMonitoringService() :
                DistributedLockScreenMonitoringService(),
            soundPlayer: isRunningUITests ?
                InactiveLockScreenSoundPlayer() :
                LockScreenSoundPlayer()
        )
    }
}
