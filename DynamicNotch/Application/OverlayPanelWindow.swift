internal import AppKit

final class OverlayPanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

enum OverlayWindowLevel {
    static let interactiveNotch = NSWindow.Level.mainMenu + 3
    static let shieldingOverlay = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
}

enum OverlayWindowLayout {
    static let appCanvasSize = CGSize(width: 1000, height: 1000)
    static let lockScreenCanvasSize = CGSize(width: 500, height: 500)

    static func topAnchoredFrame(on screen: NSScreen, size: CGSize, yOffset: CGFloat = 1) -> NSRect {
        let x = floor(screen.frame.midX - size.width / 2)
        let y = screen.frame.maxY - size.height + yOffset

        return NSRect(origin: CGPoint(x: x, y: y), size: size)
    }
}

enum OverlayPanelFactory {
    static func makePanel(frame: NSRect, level: NSWindow.Level, isFloatingPanel: Bool = true) -> OverlayPanelWindow {
        let window = OverlayPanelWindow(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configure(window, level: level, isFloatingPanel: isFloatingPanel)
        return window
    }

    static func configure(_ window: NSPanel, level: NSWindow.Level, isFloatingPanel: Bool = true) {
        window.isReleasedWhenClosed = false
        window.isFloatingPanel = isFloatingPanel
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hidesOnDeactivate = false
        window.isMovable = false
        window.hasShadow = false
        window.animationBehavior = .none
        window.level = level
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
    }
}
