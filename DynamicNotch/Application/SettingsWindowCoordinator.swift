import SwiftUI

@MainActor
enum SettingsWindowCoordinator {
    static let identifier = NSUserInterfaceItemIdentifier(WindowsScene.settings)

    static func configure(_ window: NSWindow) {
        if let existingWindow = settingsWindow(excluding: window) {
            window.close()
            focus(existingWindow)
            return
        }

        window.identifier = identifier
    }

    @discardableResult
    static func activateExisting() -> Bool {
        guard let window = settingsWindow() else {
            return false
        }

        focus(window)
        return true
    }

    static func activate(attempts: Int = 6) {
        NSApp.activate(ignoringOtherApps: true)
        focusWindow(attempts: attempts)
    }

    private static func focusWindow(attempts: Int) {
        if let window = settingsWindow() {
            focus(window)
            return
        }

        guard attempts > 0 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            focusWindow(attempts: attempts - 1)
        }
    }

    private static func settingsWindow(excluding excludedWindow: NSWindow? = nil) -> NSWindow? {
        NSApp.windows.first {
            $0.identifier == identifier && $0 !== excludedWindow
        }
    }

    private static func focus(_ window: NSWindow) {
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsWindowBridge: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ObserverView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        SettingsWindowCoordinator.configure(window)
    }
}

extension SettingsWindowBridge {
    final class ObserverView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            guard let window else { return }
            SettingsWindowCoordinator.configure(window)
            SettingsWindowCoordinator.activate()
        }
    }
}
