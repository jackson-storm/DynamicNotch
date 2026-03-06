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
    let notchViewModel = NotchViewModel()
    let powerService = PowerService()
    let bluetoothViewModel = BluetoothViewModel()
    let powerViewModel: PowerViewModel
    let networkViewModel = NetworkViewModel()
    let focusViewModel = FocusViewModel()
    let airDropViewModel = AirDropNotchViewModel()
    
    lazy var notchEventCoordinator = NotchEventCoordinator(
        notchViewModel: notchViewModel,
        bluetoothViewModel: bluetoothViewModel,
        powerService: powerService,
        networkViewModel: networkViewModel,
        airDropViewModel: airDropViewModel
    )
    
    var window: NSWindow!
    
    override init() {
        self.powerViewModel = PowerViewModel(powerService: powerService)
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
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
        notchEventCoordinator.checkFirstLaunch()
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
        
        window.contentView = NotchHostingView(
            rootView: NotchView(
                notchViewModel: notchViewModel,
                notchEventCoordinator: notchEventCoordinator,
                powerViewModel: powerViewModel,
                bluetoothViewModel: bluetoothViewModel,
                networkViewModel: networkViewModel,
                focusViewModel: focusViewModel,
                airDropViewModel: airDropViewModel
            )
        )
        
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

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return super.hitTest(point)
    }
}
