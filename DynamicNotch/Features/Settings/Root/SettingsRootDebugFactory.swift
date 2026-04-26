#if DEBUG
import Foundation

private struct SettingsRootDebugDependencies {
    let notchViewModel: NotchViewModel
    let notchEventCoordinator: NotchEventCoordinator
    let bluetoothViewModel: BluetoothViewModel
    let powerService: PowerService
    let networkViewModel: NetworkViewModel
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
        networkViewModel: NetworkViewModel?,
        downloadViewModel: DownloadViewModel?,
        nowPlayingViewModel: NowPlayingViewModel?,
        timerViewModel: TimerViewModel?,
        lockScreenManager: LockScreenManager?
    ) -> DebugSettingsViewModel {
        let dependencies = resolveDebugDependencies(
            settingsViewModel: settingsViewModel,
            notchViewModel: notchViewModel,
            notchEventCoordinator: notchEventCoordinator,
            bluetoothViewModel: bluetoothViewModel,
            powerService: powerService,
            networkViewModel: networkViewModel,
            downloadViewModel: downloadViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            timerViewModel: timerViewModel,
            lockScreenManager: lockScreenManager
        )

        return DebugSettingsViewModel(
            notchViewModel: dependencies.notchViewModel,
            notchEventCoordinator: dependencies.notchEventCoordinator,
            bluetoothViewModel: dependencies.bluetoothViewModel,
            powerService: dependencies.powerService,
            networkViewModel: dependencies.networkViewModel,
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
        networkViewModel: NetworkViewModel?,
        downloadViewModel: DownloadViewModel?,
        nowPlayingViewModel: NowPlayingViewModel?,
        timerViewModel: TimerViewModel?,
        lockScreenManager: LockScreenManager?
    ) -> SettingsRootDebugDependencies {
        let resolvedNotchViewModel = notchViewModel ?? NotchViewModel(
            settings: settingsViewModel.application
        )
        let resolvedBluetoothViewModel = bluetoothViewModel ?? BluetoothViewModel()
        let resolvedPowerService = powerService ?? PowerService(startMonitoring: false)
        let resolvedNetworkViewModel = networkViewModel ?? NetworkViewModel(
            settings: settingsViewModel.connectivity
        )
        let resolvedDownloadViewModel = downloadViewModel ?? DownloadViewModel(
            monitor: InactiveDownloadMonitor()
        )
        let resolvedAirDropViewModel = AirDropNotchViewModel()
        let resolvedFileTrayViewModel = FileTrayViewModel()
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
        let resolvedCoordinator = notchEventCoordinator ?? NotchEventCoordinator(
            notchViewModel: resolvedNotchViewModel,
            bluetoothViewModel: resolvedBluetoothViewModel,
            powerService: resolvedPowerService,
            networkViewModel: resolvedNetworkViewModel,
            downloadViewModel: resolvedDownloadViewModel,
            airDropViewModel: resolvedAirDropViewModel,
            fileTrayViewModel: resolvedFileTrayViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: resolvedNowPlayingViewModel,
            timerViewModel: resolvedTimerViewModel,
            lockScreenManager: resolvedLockScreenManager
        )

        return SettingsRootDebugDependencies(
            notchViewModel: resolvedNotchViewModel,
            notchEventCoordinator: resolvedCoordinator,
            bluetoothViewModel: resolvedBluetoothViewModel,
            powerService: resolvedPowerService,
            networkViewModel: resolvedNetworkViewModel,
            downloadViewModel: resolvedDownloadViewModel,
            nowPlayingViewModel: resolvedNowPlayingViewModel,
            lockScreenManager: resolvedLockScreenManager,
            timerViewModel: resolvedTimerViewModel
        )
    }
}
#endif
