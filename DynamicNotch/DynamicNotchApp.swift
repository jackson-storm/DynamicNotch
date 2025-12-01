import SwiftUI

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
        }
        .windowStyle(.plain)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let window = NSApplication.shared.windows.first else { return }
        
        window.layoutIfNeeded()
        
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.tabbingMode = .disallowed
        window.isExcludedFromWindowsMenu = true
        
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        window.styleMask.remove([.resizable, .miniaturizable])

        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .stationary]

        window.styleMask.insert(.nonactivatingPanel)
        window.styleMask.insert(.fullSizeContentView)

        guard let screen = window.screen ?? NSScreen.main else { return }
        let screenFrame = screen.frame

        var frame = window.frame
        let maxWidth = screenFrame.width
        let maxHeight = screenFrame.height
        if frame.width > maxWidth { frame.size.width = maxWidth }
        if frame.height > maxHeight { frame.size.height = maxHeight }

        let centeredX = screenFrame.midX - (frame.width / 2.0)
        let topAlignedY = screenFrame.maxY - frame.height
        frame.origin = NSPoint(x: centeredX, y: topAlignedY)

        window.setFrame(frame, display: true)
    }
}
