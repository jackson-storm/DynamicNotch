import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private func positionWindowUnderMenuBar(_ window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let vf = screen.visibleFrame

        let topInset: CGFloat = -41

        var frame = window.frame
        frame.size.width = min(frame.size.width, vf.size.width)
        if frame.size.height > vf.size.height - topInset {
            frame.size.height = vf.size.height - topInset
        }

        let centeredX = vf.midX - (frame.size.width / 2.0)
        let topAlignedY = vf.maxY - frame.size.height - topInset
        frame.origin = NSPoint(x: centeredX, y: topAlignedY)

        window.setFrame(frame, display: true)
    }

    @objc private func handleScreenParametersChanged(_ notification: Notification) {
        guard let window = NSApplication.shared.windows.first else { return }
        positionWindowUnderMenuBar(window)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let window = NSApplication.shared.windows.first else { return }
        window.delegate = self
        
        NSApp.setActivationPolicy(.accessory)
        
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

        positionWindowUnderMenuBar(window)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleScreenParametersChanged(_:)),
                                               name: NSApplication.didChangeScreenParametersNotification,
                                               object: nil)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        positionWindowUnderMenuBar(window)
    }
}
