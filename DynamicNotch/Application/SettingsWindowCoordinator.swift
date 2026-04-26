import SwiftUI

@MainActor
enum SettingsWindowCoordinator {
    static let identifier = NSUserInterfaceItemIdentifier(WindowsScene.settings)

    static func configure(_ window: NSWindow) {
        window.identifier = identifier
    }

    static func activate(attempts: Int = 6) {
        NSApp.activate(ignoringOtherApps: true)
        focusWindow(attempts: attempts)
    }

    private static func focusWindow(attempts: Int) {
        if let window = NSApp.windows.first(where: { $0.identifier == identifier }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        guard attempts > 0 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            focusWindow(attempts: attempts - 1)
        }
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
