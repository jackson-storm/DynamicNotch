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

    var settingsViewModel: SettingsViewModel { container.settingsViewModel }
    var notchViewModel: NotchViewModel { container.notchViewModel }
    var notchEventCoordinator: NotchEventCoordinator { container.notchEventCoordinator }
    var hardwareHUDMonitor: HardwareHUDMonitor { container.hardwareHUDMonitor }
    var lockScreenPanelManager: LockScreenPanelManager { container.lockScreenPanelManager }
    var lockScreenLiveActivityWindowManager: LockScreenLiveActivityWindowManager { container.lockScreenLiveActivityWindowManager }
    var airDropViewModel: AirDropNotchViewModel { container.airDropViewModel }
    var airDropController: NotchAirDropController { container.airDropController }
    var lockScreenManager: LockScreenManager { container.lockScreenManager }
    var nowPlayingViewModel: NowPlayingViewModel { container.nowPlayingViewModel }
    var downloadViewModel: DownloadViewModel { container.downloadViewModel }
    var timerViewModel: TimerViewModel { container.timerViewModel }
    var screenRecordingViewModel: ScreenRecordingViewModel { container.screenRecordingViewModel }
    var mailManager: MailManager { container.mailManager }
    var messagesManager: MessagesManager { container.messagesManager }
    var externalDrivesMonitor: ExternalDrivesMonitor { container.externalDrivesMonitor }
    var powerService: PowerService { container.powerService }
    var powerViewModel: PowerViewModel { container.powerViewModel }
    var bluetoothViewModel: BluetoothViewModel { container.bluetoothViewModel }
    var wifiViewModel: WifiViewModel { container.wifiViewModel }
    var vpnViewModel: VpnViewModel { container.vpnViewModel }
    var focusViewModel: FocusViewModel { container.focusViewModel }
    
    var window: OverlayPanelWindow!
    var localClickMonitor: Any?
    let globalClickMonitor = GlobalClickMonitor()
    var cancellables = Set<AnyCancellable>()
    var isPrimaryWindowSuspendedForLock = false
    var expansionTime: Date = .distantPast
    
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
            _ = lockScreenLiveActivityWindowManager
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
        container.lockScreenManager.stopMonitoring()
        container.nowPlayingViewModel.stopMonitoring()
        container.downloadViewModel.stopMonitoring()
        container.timerViewModel.stopMonitoring()
        container.screenRecordingViewModel.stopMonitoring()
        container.hardwareHUDMonitor.stopMonitoring()
        if !isRunningUITests {
            container.lockScreenPanelManager.invalidate()
            container.lockScreenLiveActivityWindowManager.invalidate()
        }
        stopOutsideClickMonitoring()
        container.mailManager.stopMonitoring()
        container.messagesManager.stopMonitoring()
        container.externalDrivesMonitor.stopMonitoring()
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
