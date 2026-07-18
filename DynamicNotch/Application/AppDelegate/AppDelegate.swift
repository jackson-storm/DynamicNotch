//
//  AppDelegate.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let isRunningUITests: Bool
    let container: AppContainer

    var powerService: PowerService { container.powerService }
    var bluetoothViewModel: BluetoothViewModel { container.bluetoothViewModel }
    var powerViewModel: PowerViewModel { container.powerViewModel }
    var wifiViewModel: WifiViewModel { container.wifiViewModel }
    var vpnViewModel: VpnViewModel { container.vpnViewModel }
    var downloadViewModel: DownloadViewModel { container.downloadViewModel }
    var focusViewModel: FocusViewModel { container.focusViewModel }
    var settingsViewModel: SettingsViewModel { container.settingsViewModel }
    var nowPlayingViewModel: NowPlayingViewModel { container.nowPlayingViewModel }
    var timerViewModel: TimerViewModel { container.timerViewModel }
    var screenRecordingViewModel: ScreenRecordingViewModel { container.screenRecordingViewModel }
    var airDropViewModel: AirDropNotchViewModel { container.airDropViewModel }
    var lockScreenManager: LockScreenManager { container.lockScreenManager }
    var hardwareHUDMonitor: HardwareHUDMonitor { container.hardwareHUDMonitor }
    var notchViewModel: NotchViewModel { container.notchViewModel }
    var airDropController: NotchAirDropController { container.airDropController }
    var notchEventCoordinator: NotchEventCoordinator { container.notchEventCoordinator }
    var lockScreenPanelManager: LockScreenPanelManager { container.lockScreenPanelManager }
    var lockScreenLiveActivityWindowManager: LockScreenLiveActivityWindowManager { container.lockScreenLiveActivityWindowManager }
    var homePageViewModel: HomePageViewModel { container.homePageViewModel }
    
    var window: OverlayPanelWindow!
    var localClickMonitor: Any?
    let globalClickMonitor = GlobalClickMonitor()
    var cancellables = Set<AnyCancellable>()
    var isPrimaryWindowSuspendedForLock = false
    
    override init() {
        let isRunningUITests = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        self.isRunningUITests = isRunningUITests
        self.container = AppContainer(isRunningUITests: isRunningUITests)
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        applyActivationPolicy(
            showsDockIcon: isRunningUITests || settingsViewModel.application.isDockIconVisible
        )
        observeDisplayLocationChanges()
        observeFullscreenVisibilityChanges()
        observeDockIconVisibilityChanges()
        observeHUDConfigurationChanges()
        observeFeatureMonitoringChanges()
        observeLockScreenWindowHandoff()
        
        SettingsWindowController.shared.setupDependencies(appDelegate: self)

        if !isRunningUITests {
            createNotchWindow()
            observeOutsideClickDismissal()
            _ = lockScreenPanelManager
            hardwareHUDMonitor.startMonitoring()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateWindowFrame),
                name: NSApplication.didChangeScreenParametersNotification,
                object: nil
            )
            observeWorkspaceChanges()

            DispatchQueue.main.async {
                for w in NSApp.windows {
                    if w !== self.window {
                        w.orderOut(nil)
                    }
                }
            }
        }

        if !isRunningUITests {
            notchEventCoordinator.checkFirstLaunch()
            
            // Наблюдаем за появлением обновлений ПО для показа Live Activity
            SparkleUpdater.shared.$isUpdateAvailable
                .receive(on: RunLoop.main)
                .sink { [weak self] isAvailable in
                    guard let self else { return }
                    if isAvailable {
                        let content = SoftwareUpdateNotchContent(settingsViewModel: self.settingsViewModel)
                        self.notchViewModel.send(.showLiveActivity(content))
                    } else {
                        self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Settings.softwareUpdate.id))
                    }
                }
                .store(in: &cancellables)
        }

        lockScreenManager.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        lockScreenManager.stopMonitoring()
        nowPlayingViewModel.stopMonitoring()
        downloadViewModel.stopMonitoring()
        timerViewModel.stopMonitoring()
        screenRecordingViewModel.stopMonitoring()
        hardwareHUDMonitor.stopMonitoring()
        if !isRunningUITests {
            lockScreenPanelManager.invalidate()
        }
        stopOutsideClickMonitoring()
    }

    func applyActivationPolicy(showsDockIcon: Bool) {
        let targetPolicy: NSApplication.ActivationPolicy = showsDockIcon ? .regular : .accessory

        guard NSApp.activationPolicy() != targetPolicy else { return }

        NSApp.setActivationPolicy(targetPolicy)

        if showsDockIcon {
            NSApp.activate(ignoringOtherApps: false)
        }
    }
}
