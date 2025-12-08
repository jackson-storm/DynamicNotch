import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {

        guard let screen = NSScreen.screens.first else { return }
        let screenFrame = screen.frame
        let safeInsets = screen.safeAreaInsets

        let contentView = ContentView(safeInsetsTop: safeInsets.top)

        window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        
        window.level = .statusBar

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        window.styleMask.insert(.nonactivatingPanel)

        window.isMovable = false
        window.isMovableByWindowBackground = false

        window.tabbingMode = .disallowed
        window.isExcludedFromWindowsMenu = true

        window.contentView = NSHostingView(rootView: contentView)

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}
