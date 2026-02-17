import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let notchViewModel = NotchViewModel()
    let powerViewModel = PowerViewModel(powerMonitor: PowerSourceMonitor())
    let playerViewModel = PlayerViewModel()
    let bluetoothViewModel = BluetoothViewModel()
    
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
        window.level = .screenSaver
        
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
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
                window: window
            )
        )
        
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc
    func updateWindowFrame() {
        guard let screen = window.screen ?? NSScreen.main else { return }
        
        let frame = screen.frame
        let size = window.frame.size
        
        let x = frame.midX - size.width / 2
        let y = frame.maxY - size.height
        
        window.setFrame(
            NSRect(origin: CGPoint(x: x, y: y), size: size),
            display: true,
            animate: false
        )
    }
}
