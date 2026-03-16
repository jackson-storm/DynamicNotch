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
    let focusViewModel = FocusViewModel()
    let airDropViewModel = AirDropNotchViewModel()
    let generalSettingsViewModel = GeneralSettingsViewModel()
    let nowPlayingViewModel: NowPlayingViewModel
    let lockScreenManager: LockScreenManager
    
    lazy var notchViewModel = NotchViewModel(settings: generalSettingsViewModel)
    lazy var notchEventCoordinator = NotchEventCoordinator(
        notchViewModel: notchViewModel,
        bluetoothViewModel: bluetoothViewModel,
        powerService: powerService,
        networkViewModel: networkViewModel,
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
    private var localScrollMonitor: Any?
    private var globalScrollMonitor: Any?
    private var localClickMonitor: Any?
    private let globalClickMonitor = GlobalClickMonitor()
    private var cancellables = Set<AnyCancellable>()
    private var isPrimaryWindowSuspendedForLock = false
    
    override init() {
        self.powerViewModel = PowerViewModel(powerService: powerService)
        self.nowPlayingViewModel = NowPlayingViewModel(
            service: ProcessInfo.processInfo.arguments.contains("-ui-testing") ?
                InactiveNowPlayingService() :
                MediaRemoteNowPlayingService()
        )
        self.lockScreenManager = LockScreenManager(
            service: ProcessInfo.processInfo.arguments.contains("-ui-testing") ?
                InactiveLockScreenMonitoringService() :
                DistributedLockScreenMonitoringService()
        )
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(isRunningUITests ? .regular : .accessory)
        observeDisplayLocationChanges()
        observeLockScreenWindowHandoff()

        if !isRunningUITests {
            createNotchWindow()
            observeOutsideClickDismissal()
            _ = lockScreenPanelManager
            _ = lockScreenLiveActivityWindowManager

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
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        lockScreenManager.stopMonitoring()
        if !isRunningUITests {
            lockScreenPanelManager.invalidate()
            lockScreenLiveActivityWindowManager.invalidate()
        }
        stopOutsideClickMonitoring()
        stopDismissGestureMonitoring()
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
            level: NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        )
        
        let hostingView = NotchHostingView(
            rootView: NotchView(
                notchViewModel: notchViewModel,
                notchEventCoordinator: notchEventCoordinator,
                powerViewModel: powerViewModel,
                bluetoothViewModel: bluetoothViewModel,
                networkViewModel: networkViewModel,
                focusViewModel: focusViewModel,
                airDropViewModel: airDropViewModel,
                generalSettingsViewModel: generalSettingsViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                lockScreenManager: lockScreenManager
            )
        )
        airDropViewModel.presentationView = hostingView

        hostingView.activeNotchSizeProvider = { [weak self] in
            guard let self else { return .zero }
            return self.notchViewModel.notchModel.size
        }

        hostingView.isDismissGestureEnabled = { [weak self] in
            guard let self else { return false }
            return self.notchViewModel.notchModel.content != nil
        }

        hostingView.onTwoFingerSwipeUp = { [weak self] in
            guard let self else { return }
            self.notchViewModel.dismissActiveContent()
        }

        window.contentView = hostingView
        SkyLightOperator.shared.delegateWindow(window)

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

    private func observeLockScreenWindowHandoff() {
        Publishers.CombineLatest(
            lockScreenManager.$isLocked.removeDuplicates(),
            lockScreenManager.$isLockIdle.removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isLocked, isLockIdle in
            guard let self, !self.isRunningUITests else { return }

            if isLocked {
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

    private func stopDismissGestureMonitoring() {
        if let localScrollMonitor {
            NSEvent.removeMonitor(localScrollMonitor)
        }

        if let globalScrollMonitor {
            NSEvent.removeMonitor(globalScrollMonitor)
        }

        localScrollMonitor = nil
        globalScrollMonitor = nil
    }

    private func openSettingsWindowForUITests() {
        DispatchQueue.main.async {
            let hostingController = NSHostingController(
                rootView: SettingsRootView(
                    powerService: self.powerService,
                    generalSettingsViewModel: self.generalSettingsViewModel
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
    var activeNotchSizeProvider: (() -> CGSize)?
    var isDismissGestureEnabled: (() -> Bool)?
    var onTwoFingerSwipeUp: (() -> Void)?

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

    func containsActiveNotch(atScreenLocation screenLocation: NSPoint) -> Bool {
        guard let activeNotchScreenRect = currentActiveNotchScreenRect() else { return false }
        return activeNotchScreenRect.contains(screenLocation)
    }
}

private extension NotchHostingView {
    func shouldTrackDismissGesture(for event: NSEvent) -> Bool {
        guard event.hasPreciseScrollingDeltas else { return false }
        guard event.momentumPhase.isEmpty else { return false }
        guard isDismissGestureEnabled?() == true else { return false }
        return true
    }

    func currentActiveNotchRect() -> CGRect? {
        guard let notchSize = activeNotchSizeProvider?(),
              notchSize.width > 0,
              notchSize.height > 0 else {
            return nil
        }

        let origin = CGPoint(
            x: floor((bounds.width - notchSize.width) / 2),
            y: bounds.height - notchSize.height
        )

        return CGRect(origin: origin, size: notchSize).insetBy(dx: -12, dy: -8)
    }

    func currentActiveNotchScreenRect() -> CGRect? {
        guard let activeNotchRect = currentActiveNotchRect(),
              let window else {
            return nil
        }

        let rectInWindow = convert(activeNotchRect, to: nil)
        return window.convertToScreen(rectInWindow)
    }

    func physicalVerticalDelta(from event: NSEvent) -> CGFloat {
        let deltaY = CGFloat(event.scrollingDeltaY)
        return event.isDirectionInvertedFromDevice ? -deltaY : deltaY
    }

    func physicalHorizontalDelta(from event: NSEvent) -> CGFloat {
        let deltaX = CGFloat(event.scrollingDeltaX)
        return event.isDirectionInvertedFromDevice ? -deltaX : deltaX
    }
}
