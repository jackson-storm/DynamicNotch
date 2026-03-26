//
//  AppDelegate.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let isRunningUITests = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    let powerService = PowerService()
    let bluetoothViewModel = BluetoothViewModel()
    let powerViewModel: PowerViewModel
    let networkViewModel = NetworkViewModel()
    let downloadViewModel: DownloadViewModel
    let focusViewModel = FocusViewModel()
    let generalSettingsViewModel = GeneralSettingsViewModel()
    let nowPlayingViewModel: NowPlayingViewModel
    let airDropViewModel = AirDropNotchViewModel()
    let lockScreenManager: LockScreenManager
    
    lazy var hardwareHUDMonitor: HardwareHUDMonitor = {
        let monitor = HardwareHUDMonitor()
        monitor.onEvent = { [weak self] event in
            self?.notchEventCoordinator.handleHudEvent(event)
        }
        monitor.updateConfiguration(
            interceptVolume: generalSettingsViewModel.isVolumeHUDEnabled,
            interceptBrightness: generalSettingsViewModel.isBrightnessHUDEnabled
        )
        return monitor
    }()
    
    lazy var notchViewModel = NotchViewModel(settings: generalSettingsViewModel)
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
    
    var window: OverlayPanelWindow!
    private var uiTestSettingsWindow: NSWindow?
    private var localClickMonitor: Any?
    private let globalClickMonitor = GlobalClickMonitor()
    private var cancellables = Set<AnyCancellable>()
    private var isPrimaryWindowSuspendedForLock = false
    
    override init() {
        let isRunningUITests = ProcessInfo.processInfo.arguments.contains("-ui-testing")

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

        if isRunningUITests {
            openSettingsWindowForUITests()
        } else {
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
    
    func createNotchWindow() {
        guard let screen = NSScreen.preferredNotchScreen(for: generalSettingsViewModel.displayLocation) else {
            return
        }

        let frame = OverlayWindowLayout.topAnchoredFrame(
            on: screen,
            size: OverlayWindowLayout.appCanvasSize
        )

        window = OverlayPanelFactory.makePanel(
            frame: frame,
            level: OverlayWindowLevel.interactiveNotch
        )
        
        let hostingView = NotchHostingView(
            rootView: NotchView(
                notchViewModel: notchViewModel,
                notchEventCoordinator: notchEventCoordinator,
                powerViewModel: powerViewModel,
                bluetoothViewModel: bluetoothViewModel,
                networkViewModel: networkViewModel,
                downloadViewModel: downloadViewModel,
                focusViewModel: focusViewModel,
                airDropViewModel: airDropViewModel,
                airDropController: airDropController,
                generalSettingsViewModel: generalSettingsViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                lockScreenManager: lockScreenManager
            )
        )

        window.contentView = hostingView
        SkyLightOperator.shared.delegateWindow(window, to: .notchSurface)

        window.orderFrontRegardless()
    }
    
    @objc func updateWindowFrame() {
        guard let window = self.window else { return }
        
        notchViewModel.updateDimensions()
        
        guard let screen = NSScreen.preferredNotchScreen(for: generalSettingsViewModel.displayLocation) else {
            return
        }

        let targetFrame = OverlayWindowLayout.topAnchoredFrame(
            on: screen,
            size: window.frame.size
        )

        window.setFrame(targetFrame, display: true, animate: false)

        if !isPrimaryWindowSuspendedForLock {
            window.orderFrontRegardless()
        }
    }

    private func observeDisplayLocationChanges() {
        generalSettingsViewModel.$displayLocation
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateWindowFrame()
            }
            .store(in: &cancellables)
    }

    private func observeHUDConfigurationChanges() {
        Publishers.CombineLatest(
            generalSettingsViewModel.$isVolumeHUDEnabled.removeDuplicates(),
            generalSettingsViewModel.$isBrightnessHUDEnabled.removeDuplicates()
        )
        .sink { [weak self] isVolumeHUDEnabled, isBrightnessHUDEnabled in
            self?.hardwareHUDMonitor.updateConfiguration(
                interceptVolume: isVolumeHUDEnabled,
                interceptBrightness: isBrightnessHUDEnabled
            )
        }
        .store(in: &cancellables)
    }

    private func observeLockScreenWindowHandoff() {
        Publishers.CombineLatest3(
            lockScreenManager.$isLocked.removeDuplicates(),
            lockScreenManager.$isPreparingLock.removeDuplicates(),
            lockScreenManager.$isLockIdle.removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isLocked, isPreparingLock, isLockIdle in
            guard let self, !self.isRunningUITests else { return }

            if isLocked || isPreparingLock {
                self.suspendPrimaryWindowForLock()
            } else if self.isPrimaryWindowSuspendedForLock {
                self.restorePrimaryWindowForUnlockTransition()
            } else if isLockIdle {
                self.updateWindowFrame()
            }
        }
        .store(in: &cancellables)
    }

    private func suspendPrimaryWindowForLock() {
        guard let window, !isPrimaryWindowSuspendedForLock else { return }

        isPrimaryWindowSuspendedForLock = true
        window.orderOut(nil)
    }

    private func restorePrimaryWindowForUnlockTransition() {
        guard let window, isPrimaryWindowSuspendedForLock else { return }

        isPrimaryWindowSuspendedForLock = false
        updateWindowFrame()
        window.orderFrontRegardless()
    }

    private func observeWorkspaceChanges() {
        let center = NSWorkspace.shared.notificationCenter

        center.addObserver(
            self,
            selector: #selector(handleWorkspaceContextChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(handleWorkspaceContextChange),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc
    private func handleWorkspaceContextChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateWindowFrame()
        }
    }

    private func observeOutsideClickDismissal() {
        notchViewModel.$notchModel
            .map(\.isLiveActivityExpanded)
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    self.startOutsideClickMonitoring()
                } else {
                    self.stopOutsideClickMonitoring()
                }
            }
            .store(in: &cancellables)
    }

    private func startOutsideClickMonitoring() {
        if localClickMonitor == nil {
            localClickMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            ) { [weak self] event in
                let sourceWindow = event.window
                let screenLocation =
                    sourceWindow?.convertPoint(toScreen: event.locationInWindow) ??
                    NSEvent.mouseLocation

                Task { @MainActor [weak self] in
                    self?.handleLocalClick(from: sourceWindow, atScreenLocation: screenLocation)
                }
                return event
            }
        }

        globalClickMonitor.start { [weak self] _ in
            let screenLocation = NSEvent.mouseLocation
            Task { @MainActor [weak self] in
                self?.handleGlobalClick(atScreenLocation: screenLocation)
            }
        }
    }

    private func stopOutsideClickMonitoring() {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
        }

        localClickMonitor = nil
        globalClickMonitor.stop()
    }

    @MainActor
    private func handleLocalClick(from _: NSWindow?, atScreenLocation screenLocation: NSPoint) {
        guard shouldHandleOutsideClick else { return }
        guard let activeNotchScreenRect else {
            notchViewModel.handleOutsideClick()
            return
        }

        guard !activeNotchScreenRect.contains(screenLocation) else { return }

        notchViewModel.handleOutsideClick()
    }

    @MainActor
    private func handleGlobalClick(atScreenLocation screenLocation: NSPoint) {
        guard shouldHandleOutsideClick else { return }
        guard let activeNotchScreenRect else {
            notchViewModel.handleOutsideClick()
            return
        }

        guard !activeNotchScreenRect.contains(screenLocation) else { return }
        notchViewModel.handleOutsideClick()
    }

    @MainActor
    private var shouldHandleOutsideClick: Bool {
        notchViewModel.notchModel.isLiveActivityExpanded
    }

    @MainActor
    private var activeNotchScreenRect: CGRect? {
        guard let window else { return nil }

        let notchSize = notchViewModel.notchModel.size
        guard notchSize.width > 0, notchSize.height > 0 else { return nil }

        let origin = CGPoint(
            x: floor(window.frame.midX - notchSize.width / 2),
            y: window.frame.maxY - notchSize.height
        )

        return CGRect(origin: origin, size: notchSize).insetBy(dx: -12, dy: -8)
    }
    private func openSettingsWindowForUITests() {
        DispatchQueue.main.async {
            let hostingController = NSHostingController(
                rootView: SettingsRootView(
                    powerService: self.powerService,
                    generalSettingsViewModel: self.generalSettingsViewModel,
                    notchViewModel: self.notchViewModel,
                    notchEventCoordinator: self.notchEventCoordinator,
                    bluetoothViewModel: self.bluetoothViewModel,
                    networkViewModel: self.networkViewModel,
                    downloadViewModel: self.downloadViewModel,
                    nowPlayingViewModel: self.nowPlayingViewModel,
                    lockScreenManager: self.lockScreenManager
                )
            )

            let settingsWindow = NSWindow(
                contentRect: NSRect(
                    x: 0,
                    y: 0,
                    width: SettingsWindowLayout.width,
                    height: SettingsWindowLayout.height
                ),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )

            settingsWindow.title = "Settings"
            settingsWindow.center()
            settingsWindow.isReleasedWhenClosed = false
            settingsWindow.contentViewController = hostingController

            self.uiTestSettingsWindow = settingsWindow
            NSApp.activate(ignoringOtherApps: true)
            settingsWindow.makeKeyAndOrderFront(nil)
        }
    }
}

class NotchHostingView: NSHostingView<AnyView> {
    required init(rootView: AnyView) {
        super.init(rootView: rootView)
    }

    convenience init<Content: View>(rootView: Content) {
        self.init(rootView: AnyView(rootView))
    }

    @MainActor @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return super.hitTest(point)
    }
}
