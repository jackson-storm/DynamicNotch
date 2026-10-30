import Foundation

@MainActor
final class AppContainer {
    let powerService = PowerService()
    let bluetoothViewModel: BluetoothViewModel
    let focusViewModel = FocusViewModel()
    let airDropViewModel = AirDropNotchViewModel()
    let fileTrayViewModel = FileTrayViewModel()
    let settingsViewModel: SettingsViewModel
    let wifiViewModel: WifiViewModel
    let vpnViewModel: VpnViewModel
    let localTimerViewModel = LocalTimerViewModel()
    let calendarViewModel = CalendarViewModel()
    let screenshotViewModel = ScreenshotViewModel()

    let powerViewModel: PowerViewModel
    let downloadViewModel: DownloadViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let timerViewModel: TimerViewModel
    let screenRecordingViewModel: ScreenRecordingViewModel
    let screenRecordingResultViewModel = ScreenRecordingResultViewModel()
    let lockScreenManager: LockScreenManager
    let clockTimerController: any ClockTimerControlling
    let externalDrivesMonitor: ExternalDrivesMonitor

    lazy var hardwareHUDMonitor: HardwareHUDMonitor = {
        MainActor.assumeIsolated {
            let monitor = HardwareHUDMonitor()
            monitor.onEvent = { [weak self] event in
                self?.notchEventCoordinator.handleHudEvent(event)
            }
            monitor.updateConfiguration(
                interceptVolume: settingsViewModel.hud.isVolumeHUDEnabled,
                interceptBrightness: settingsViewModel.hud.isBrightnessHUDEnabled
            )
            return monitor
        }
    }()

    lazy var notchViewModel = NotchViewModel(settings: settingsViewModel.application)
    lazy var notchlessWindowConstrainer = NotchlessWindowConstrainer(settings: settingsViewModel.application)
    lazy var airDropController = NotchAirDropController(
        airDropViewModel: airDropViewModel,
        fileTrayViewModel: fileTrayViewModel
    )

    lazy var notchEventCoordinator = NotchEventCoordinator(container: self)

    lazy var lockScreenPanelManager = LockScreenPanelManager(
        nowPlayingViewModel: nowPlayingViewModel,
        lockScreenManager: lockScreenManager,
        settingsViewModel: settingsViewModel
    )

    lazy var lockScreenLiveActivityWindowManager = LockScreenLiveActivityWindowManager(
        notchViewModel: notchViewModel,
        lockScreenManager: lockScreenManager,
        settingsViewModel: settingsViewModel,
        airDropViewModel: airDropViewModel,
        airDropController: airDropController
    )

    lazy var floatingLyricsWindowManager = FloatingLyricsWindowManager(
        nowPlayingViewModel: nowPlayingViewModel,
        settings: settingsViewModel.mediaAndFiles
    )

    lazy var lockScreenFaceIDWindowManager = LockScreenFaceIDWindowManager(
        lockScreenManager: lockScreenManager,
        faceIDSettings: settingsViewModel.faceID,
        settingsViewModel: settingsViewModel,
        notchViewModel: notchViewModel
    )

    init(isRunningTests: Bool? = nil) {
        let isRunningTests = isRunningTests ?? AppEnvironment.isRunningTests
        self.settingsViewModel = SettingsViewModel()
        self.wifiViewModel = WifiViewModel(settings: settingsViewModel.connectivity)
        self.vpnViewModel = VpnViewModel(settings: settingsViewModel.connectivity)
        self.powerViewModel = PowerViewModel(
            powerService: powerService,
            batterySettings: settingsViewModel.battery
        )
        self.bluetoothViewModel = BluetoothViewModel(
            bluetoothService: isRunningTests ?
                InactiveBluetoothService() :
                BluetoothService.shared
        )
        self.nowPlayingViewModel = NowPlayingViewModel(
            service: isRunningTests ?
                InactiveNowPlayingService() :
                MediaRemoteNowPlayingService(),
            audioOutputRouting: isRunningTests ?
                InactiveAudioOutputRoutingService() :
                SystemAudioOutputRoutingService(),
            lyricsProvider: isRunningTests ?
                InactiveLyricsProvider() :
                LRCLIBLyricsProvider(),
            sourceFilter: settingsViewModel.mediaAndFiles.nowPlayingSourceFilter
        )
        self.downloadViewModel = DownloadViewModel(
            monitor: isRunningTests ?
                InactiveDownloadMonitor() :
                FolderFileDownloadMonitor()
        )
        self.clockTimerController = isRunningTests ?
            InactiveClockTimerController() :
            ClockTimerController()
        self.timerViewModel = TimerViewModel(
            monitor: isRunningTests ?
                InactiveClockTimerMonitor() :
                ClockTimerMonitor(),
            controller: clockTimerController
        )
        self.screenRecordingViewModel = ScreenRecordingViewModel(
            monitor: isRunningTests ?
                InactiveScreenRecordingMonitor() :
                SystemScreenRecordingMonitor()
        )
        self.lockScreenManager = LockScreenManager(
            service: isRunningTests ?
                InactiveLockScreenMonitoringService() :
                DistributedLockScreenMonitoringService(),
            soundPlayer: isRunningTests ?
                InactiveLockScreenSoundPlayer() :
                LockScreenSoundPlayer()
        )
        self.externalDrivesMonitor = ExternalDrivesMonitor()
    }
}
