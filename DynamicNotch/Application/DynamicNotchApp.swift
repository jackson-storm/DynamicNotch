import Cocoa
import SwiftUI

@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            TabView {
                NotchControlPanel(
                    notchViewModel: appDelegate.notchViewModel,
                    notchEventCoordinator: appDelegate.notchEventCoordinator
                )
                .tabItem {
                    Image(systemName: "light.panel")
                    Text("Notch Panel")
                }
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
            }
            .frame(width: 600, height: 400)
            .background(.ultraThinMaterial)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let notchViewModel = NotchViewModel()
    let powerSourceMonitor = PowerSourceMonitor()
    let bluetoothViewModel = BluetoothViewModel()
    let powerViewModel: PowerViewModel
    let playerViewModel = PlayerViewModel()
    let vpnViewModel = VpnViewModel()
    let wifiViewModel = WiFiViewModel()
    
    lazy var notchEventCoordinator = NotchEventCoordinator(
        notchViewModel: notchViewModel,
        bluetoothViewModel: bluetoothViewModel,
        powerSourceMonitor: powerSourceMonitor,
        wifiViewModel: wifiViewModel
    )
    
    var window: NSWindow!
    
    override init() {
        self.powerViewModel = PowerViewModel(powerMonitor: powerSourceMonitor)
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
        let y = screenFrame.maxY - notchHeight
        
        window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: notchWidth, height: notchHeight),
            styleMask: [.borderless],
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
        
        window.contentView = NSHostingView(
            rootView: NotchView(
                notchViewModel: notchViewModel,
                notchEventCoordinator: notchEventCoordinator,
                powerViewModel: powerViewModel,
                playerViewModel: playerViewModel,
                bluetoothViewModel: bluetoothViewModel,
                vpnViewModel: vpnViewModel,
                wifiViewModel: wifiViewModel,
                window: window
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
        let y = screenFrame.maxY - windowSize.height
        
        window.setFrame(
            NSRect(origin: CGPoint(x: x, y: y), size: windowSize),
            display: true,
            animate: false
        )
    }
}
