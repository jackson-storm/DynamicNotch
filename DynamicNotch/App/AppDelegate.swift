import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let notchViewModel = NotchViewModel()
    let powerViewModel = PowerViewModel(powerMonitor: PowerSourceMonitor())
    let playerViewModel = PlayerViewModel()
    let bluetoothViewModel = BluetoothViewModel()
    let networkViewModel = NetworkViewModel()
    
    var window: NSWindow!
    
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
        notchViewModel.checkFirstLaunch()
    }
    
    func createNotchWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        
        let notchWidth: CGFloat = 600
        let notchHeight: CGFloat = 600
        
        let x = screenFrame.midX - notchWidth / 2
        let y = screenFrame.maxY - notchHeight
        
        window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: notchWidth, height: notchHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        
        window.ignoresMouseEvents = true
        window.hasShadow = false
        
        window.contentView = NSHostingView(
            rootView: NotchView(
                notchViewModel: notchViewModel,
                powerViewModel: powerViewModel,
                playerViewModel: playerViewModel,
                bluetoothViewModel: bluetoothViewModel,
                networkViewModel: networkViewModel,
                window: window
            )
        )
        
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc func updateWindowFrame() {
        notchViewModel.updateDimensions()
        
        guard let screen = window.screen ?? NSScreen.main else { return }
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        
        let x = floor(screenFrame.midX - windowSize.width / 2)
        let y = screenFrame.maxY - windowSize.height
        
        window.setFrame(
            NSRect(origin: CGPoint(x: x, y: y), size: windowSize),
            display: true,
            animate: false
        )
    }
}
