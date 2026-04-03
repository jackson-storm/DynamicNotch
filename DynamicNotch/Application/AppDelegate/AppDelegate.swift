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
    var networkViewModel: NetworkViewModel { container.networkViewModel }
    var downloadViewModel: DownloadViewModel { container.downloadViewModel }
    var focusViewModel: FocusViewModel { container.focusViewModel }
    var generalSettingsViewModel: GeneralSettingsViewModel { container.generalSettingsViewModel }
    var nowPlayingViewModel: NowPlayingViewModel { container.nowPlayingViewModel }
    var airDropViewModel: AirDropNotchViewModel { container.airDropViewModel }
    var lockScreenManager: LockScreenManager { container.lockScreenManager }
    var hardwareHUDMonitor: HardwareHUDMonitor { container.hardwareHUDMonitor }
    var notchViewModel: NotchViewModel { container.notchViewModel }
    var airDropController: NotchAirDropController { container.airDropController }
    var notchEventCoordinator: NotchEventCoordinator { container.notchEventCoordinator }
    var lockScreenPanelManager: LockScreenPanelManager { container.lockScreenPanelManager }
    var lockScreenLiveActivityWindowManager: LockScreenLiveActivityWindowManager {
        container.lockScreenLiveActivityWindowManager
    }
    
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
        NSApp.setActivationPolicy(isRunningUITests ? .regular : .accessory)
        observeDisplayLocationChanges()
        observeHUDConfigurationChanges()
        observeLockScreenWindowHandoff()

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
        }

        lockScreenManager.startMonitoring()
        nowPlayingViewModel.startMonitoring()
        downloadViewModel.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        lockScreenManager.stopMonitoring()
        downloadViewModel.stopMonitoring()
        hardwareHUDMonitor.stopMonitoring()
        if !isRunningUITests {
            lockScreenPanelManager.invalidate()
            lockScreenLiveActivityWindowManager.invalidate()
        }
        stopOutsideClickMonitoring()
    }
}
