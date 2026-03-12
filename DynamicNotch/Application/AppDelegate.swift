//
//  AppDelegate.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/28/26.
//

import SwiftUI

class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let isRunningUITests = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    let powerService = PowerService()
    let bluetoothViewModel = BluetoothViewModel()
    let powerViewModel: PowerViewModel
    let networkViewModel = NetworkViewModel()
    let focusViewModel = FocusViewModel()
    let airDropViewModel = AirDropNotchViewModel()
    let generalSettingsViewModel = GeneralSettingsViewModel()
    
    lazy var notchViewModel = NotchViewModel(settings: generalSettingsViewModel)
    lazy var notchEventCoordinator = NotchEventCoordinator(
        notchViewModel: notchViewModel,
        bluetoothViewModel: bluetoothViewModel,
        powerService: powerService,
        networkViewModel: networkViewModel,
        airDropViewModel: airDropViewModel,
        generalSettingsViewModel: generalSettingsViewModel
    )
    
    var window: NSWindow!
    private var uiTestSettingsWindow: NSWindow?
    private var localScrollMonitor: Any?
    private var globalScrollMonitor: Any?
    
    override init() {
        self.powerViewModel = PowerViewModel(powerService: powerService)
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(isRunningUITests ? .regular : .accessory)

        if !isRunningUITests {
            createNotchWindow()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateWindowFrame),
                name: NSApplication.didChangeScreenParametersNotification,
                object: nil
            )

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
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopDismissGestureMonitoring()
    }
    
    func createNotchWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        
        let notchWidth: CGFloat = 1000
        let notchHeight: CGFloat = 1000
        
        let x = screenFrame.midX - notchWidth / 2
        let y = screenFrame.maxY - notchHeight + 1
        
        window = NotchPanel(
            contentRect: NSRect(x: x, y: y, width: notchWidth, height: notchHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isMovable = false
        
        window.collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]
        
        window.isReleasedWhenClosed = false
        window.level = .mainMenu + 3
        window.hasShadow = false
        
        let hostingView = NotchHostingView(
            rootView: NotchView(
                notchViewModel: notchViewModel,
                notchEventCoordinator: notchEventCoordinator,
                powerViewModel: powerViewModel,
                bluetoothViewModel: bluetoothViewModel,
                networkViewModel: networkViewModel,
                focusViewModel: focusViewModel,
                airDropViewModel: airDropViewModel,
                generalSettingsViewModel: generalSettingsViewModel
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
        
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc func updateWindowFrame() {
        guard let window = self.window else { return }
        
        notchViewModel.updateDimensions()
        
        guard let screen = window.screen ?? NSScreen.main else { return }
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        
        let x = floor(screenFrame.midX - windowSize.width / 2)
        let y = screenFrame.maxY - windowSize.height + 1
        
        window.setFrame(
            NSRect(origin: CGPoint(x: x, y: y), size: windowSize),
            display: true,
            animate: false
        )
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
                    notchViewModel: self.notchViewModel,
                    powerService: self.powerService,
                    notchEventCoordinator: self.notchEventCoordinator,
                    generalSettingsViewModel: self.generalSettingsViewModel
                )
            )

            let settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 560),
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

    func pointerLocation(for event: NSEvent, screenLocation: NSPoint?) -> NSPoint {
        if let screenLocation, let window {
            let locationInWindow = window.convertPoint(fromScreen: screenLocation)
            return convert(locationInWindow, from: nil)
        }

        return convert(event.locationInWindow, from: nil)
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
