import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let window = NSApplication.shared.windows.first else { return }

        window.delegate = self

        NSApp.setActivationPolicy(.accessory)

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func handleScreenParametersChanged(_ notification: Notification) {
        guard let window = NSApplication.shared.windows.first else { return }
        positionWindowUnderMenuBar(window)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        positionWindowUnderMenuBar(window)
    }

    private func positionWindowUnderMenuBar(_ window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }

        let full = screen.frame
        let visible = screen.visibleFrame

        let topCut = full.maxY - visible.maxY

        let hasNotch = topCut > 40

        var frame = window.frame
        frame.size.width = min(frame.size.width, visible.width)
        frame.origin.x = visible.midX - frame.size.width / 2

        if hasNotch {
            let notchHeight = topCut - 22
            let y = full.maxY - notchHeight - frame.height
            frame.origin.y = y
        } else {
            frame.origin.y = visible.maxY - frame.height + 196
        }

        window.setFrame(frame, display: true, animate: true)
    }
}
