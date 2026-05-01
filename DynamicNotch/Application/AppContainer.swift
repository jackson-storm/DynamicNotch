import Foundation

@MainActor
final class AppContainer {
    let powerService = PowerService()
    let bluetoothViewModel = BluetoothViewModel()
    let focusViewModel = FocusViewModel()
    let airDropViewModel = AirDropNotchViewModel()
    let fileTrayViewModel = FileTrayViewModel()
    let settingsViewModel: SettingsViewModel
    let networkViewModel: NetworkViewModel

    let powerViewModel: PowerViewModel
    let downloadViewModel: DownloadViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let timerViewModel: TimerViewModel
    let screenRecordingViewModel: ScreenRecordingViewModel
    let lockScreenManager: LockScreenManager
    let clockTimerController: any ClockTimerControlling

    lazy var hardwareHUDMonitor: HardwareHUDMonitor = {
        let monitor = HardwareHUDMonitor()
        monitor.onEvent = { [weak self] event in
            self?.notchEventCoordinator.handleHudEvent(event)
        }
        monitor.updateConfiguration(
            interceptVolume: settingsViewModel.hud.isVolumeHUDEnabled,
            interceptBrightness: settingsViewModel.hud.isBrightnessHUDEnabled
        )
        return monitor
    }()

    lazy var notchViewModel = NotchViewModel(settings: settingsViewModel.application)
    lazy var airDropController = NotchAirDropController(
        airDropViewModel: airDropViewModel,
        fileTrayViewModel: fileTrayViewModel
    )

    lazy var notchEventCoordinator = NotchEventCoordinator(
        notchViewModel: notchViewModel,
        bluetoothViewModel: bluetoothViewModel,
        powerService: powerService,
        networkViewModel: networkViewModel,
        downloadViewModel: downloadViewModel,
        airDropViewModel: airDropViewModel,
        fileTrayViewModel: fileTrayViewModel,
        settingsViewModel: settingsViewModel,
        nowPlayingViewModel: nowPlayingViewModel,
        timerViewModel: timerViewModel,
        lockScreenManager: lockScreenManager
    )

    lazy var lockScreenPanelManager = LockScreenPanelManager(
        nowPlayingViewModel: nowPlayingViewModel,
        lockScreenManager: lockScreenManager,
        settingsViewModel: settingsViewModel
    )

    lazy var lockScreenLiveActivityWindowManager = LockScreenLiveActivityWindowManager(
        notchViewModel: notchViewModel,
        lockScreenManager: lockScreenManager,
        settingsViewModel: settingsViewModel
    )

    init(isRunningUITests: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing")) {
        self.settingsViewModel = SettingsViewModel()
        self.networkViewModel = NetworkViewModel(settings: settingsViewModel.connectivity)
        self.powerViewModel = PowerViewModel(
            powerService: powerService,
            batterySettings: settingsViewModel.battery
        )
        self.nowPlayingViewModel = NowPlayingViewModel(
            service: isRunningUITests ?
                InactiveNowPlayingService() :
                MediaRemoteNowPlayingService(),
            audioOutputRouting: isRunningUITests ?
                InactiveAudioOutputRoutingService() :
                SystemAudioOutputRoutingService(),
            mediaSettings: settingsViewModel.mediaAndFiles,
            audioLevelMonitor: isRunningUITests ?
                InactiveNowPlayingAudioLevelMonitor() :
                SystemNowPlayingAudioLevelMonitor()
        )
        self.downloadViewModel = DownloadViewModel(
            monitor: isRunningUITests ?
                InactiveDownloadMonitor() :
                FolderFileDownloadMonitor()
        )
        self.clockTimerController = isRunningUITests ?
            InactiveClockTimerController() :
            ClockTimerController()
        self.timerViewModel = TimerViewModel(
            monitor: isRunningUITests ?
                InactiveClockTimerMonitor() :
                ClockTimerMonitor(),
            controller: clockTimerController
        )
        self.screenRecordingViewModel = ScreenRecordingViewModel(
            monitor: isRunningUITests ?
                InactiveScreenRecordingMonitor() :
                SystemScreenRecordingMonitor()
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
