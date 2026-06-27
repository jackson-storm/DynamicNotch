#if DEBUG
import Foundation

private struct SettingsRootDebugDependencies {
    let notchViewModel: NotchViewModel
    let notchEventCoordinator: NotchEventCoordinator
    let bluetoothViewModel: BluetoothViewModel
    let powerService: PowerService
    let wifiViewModel: WifiViewModel
    let vpnViewModel: VpnViewModel
    let downloadViewModel: DownloadViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let lockScreenManager: LockScreenManager
    let timerViewModel: TimerViewModel
}

extension SettingsRootViewModel {
    static func makeDebugViewModel(
        settingsViewModel: SettingsViewModel,
        notchViewModel: NotchViewModel?,
        notchEventCoordinator: NotchEventCoordinator?,
        bluetoothViewModel: BluetoothViewModel?,
        powerService: PowerService?,
        wifiViewModel: WifiViewModel?,
        vpnViewModel: VpnViewModel?,
        downloadViewModel: DownloadViewModel?,
        nowPlayingViewModel: NowPlayingViewModel?,
        timerViewModel: TimerViewModel?,
        lockScreenManager: LockScreenManager?,
        homePageViewModel: HomePageViewModel?,
        localTimerViewModel: LocalTimerViewModel?,
        calendarViewModel: CalendarViewModel?
    ) -> DebugSettingsViewModel {
        let dependencies = resolveDebugDependencies(
            settingsViewModel: settingsViewModel,
            notchViewModel: notchViewModel,
            notchEventCoordinator: notchEventCoordinator,
            bluetoothViewModel: bluetoothViewModel,
            powerService: powerService,
            wifiViewModel: wifiViewModel,
            vpnViewModel: vpnViewModel,
            downloadViewModel: downloadViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            timerViewModel: timerViewModel,
            lockScreenManager: lockScreenManager,
            homePageViewModel: homePageViewModel,
            localTimerViewModel: localTimerViewModel,
            calendarViewModel: calendarViewModel
        )

        return DebugSettingsViewModel(
            notchViewModel: dependencies.notchViewModel,
            notchEventCoordinator: dependencies.notchEventCoordinator,
            bluetoothViewModel: dependencies.bluetoothViewModel,
            powerService: dependencies.powerService,
            wifiViewModel: dependencies.wifiViewModel,
            vpnViewModel: dependencies.vpnViewModel,
            downloadViewModel: dependencies.downloadViewModel,
            timerViewModel: dependencies.timerViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: dependencies.nowPlayingViewModel,
            lockScreenManager: dependencies.lockScreenManager
        )
    }

    private static func resolveDebugDependencies(
        settingsViewModel: SettingsViewModel,
        notchViewModel: NotchViewModel?,
        notchEventCoordinator: NotchEventCoordinator?,
        bluetoothViewModel: BluetoothViewModel?,
        powerService: PowerService?,
        wifiViewModel: WifiViewModel?,
        vpnViewModel: VpnViewModel?,
        downloadViewModel: DownloadViewModel?,
        nowPlayingViewModel: NowPlayingViewModel?,
        timerViewModel: TimerViewModel?,
        lockScreenManager: LockScreenManager?,
        homePageViewModel: HomePageViewModel?,
        localTimerViewModel: LocalTimerViewModel?,
        calendarViewModel: CalendarViewModel?
    ) -> SettingsRootDebugDependencies {
        let resolvedNotchViewModel = notchViewModel ?? NotchViewModel(
            settings: settingsViewModel.application
        )
        let resolvedBluetoothViewModel = bluetoothViewModel ?? BluetoothViewModel()
        let resolvedPowerService = powerService ?? PowerService(startMonitoring: false)
        let resolvedWifiViewModel = wifiViewModel ?? WifiViewModel(
            settings: settingsViewModel.connectivity
        )
        let resolvedVpnViewModel = vpnViewModel ?? VpnViewModel(
            settings: settingsViewModel.connectivity
        )
        let resolvedDownloadViewModel = downloadViewModel ?? DownloadViewModel(
            monitor: InactiveDownloadMonitor()
        )
        let resolvedAirDropViewModel = AirDropNotchViewModel()
        let resolvedFileTrayViewModel = FileTrayViewModel()
        let resolvedFileConverterViewModel = FileConverterViewModel()
        let resolvedNowPlayingViewModel = nowPlayingViewModel ?? NowPlayingViewModel(
            service: InactiveNowPlayingService()
        )
        let resolvedTimerViewModel = timerViewModel ?? TimerViewModel(
            monitor: InactiveClockTimerMonitor()
        )
        let resolvedLockScreenManager = lockScreenManager ?? LockScreenManager(
            service: InactiveLockScreenMonitoringService(),
            soundPlayer: InactiveLockScreenSoundPlayer()
        )
        let resolvedHomePageViewModel = homePageViewModel ?? HomePageViewModel()
        let resolvedLocalTimerViewModel = localTimerViewModel ?? LocalTimerViewModel()
        let resolvedCalendarViewModel = calendarViewModel ?? CalendarViewModel()
        let resolvedCoordinator = notchEventCoordinator ?? NotchEventCoordinator(
            notchViewModel: resolvedNotchViewModel,
            bluetoothViewModel: resolvedBluetoothViewModel,
            powerService: resolvedPowerService,
            wifiViewModel: resolvedWifiViewModel,
            vpnViewModel: resolvedVpnViewModel,
            downloadViewModel: resolvedDownloadViewModel,
            airDropViewModel: resolvedAirDropViewModel,
            fileTrayViewModel: resolvedFileTrayViewModel,
            fileConverterViewModel: resolvedFileConverterViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: resolvedNowPlayingViewModel,
            timerViewModel: resolvedTimerViewModel,
            lockScreenManager: resolvedLockScreenManager,
            homePageViewModel: resolvedHomePageViewModel,
            localTimerViewModel: resolvedLocalTimerViewModel,
            calendarViewModel: resolvedCalendarViewModel
        )

        return SettingsRootDebugDependencies(
            notchViewModel: resolvedNotchViewModel,
            notchEventCoordinator: resolvedCoordinator,
            bluetoothViewModel: resolvedBluetoothViewModel,
            powerService: resolvedPowerService,
            wifiViewModel: resolvedWifiViewModel,
            vpnViewModel: resolvedVpnViewModel,
            downloadViewModel: resolvedDownloadViewModel,
            nowPlayingViewModel: resolvedNowPlayingViewModel,
            lockScreenManager: resolvedLockScreenManager,
            timerViewModel: resolvedTimerViewModel
        )
    }
}
#endif
