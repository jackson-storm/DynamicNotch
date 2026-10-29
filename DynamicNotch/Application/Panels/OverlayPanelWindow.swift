internal import AppKit

final class OverlayPanelWindow: NSPanel {
    var allowsKeyWindow: Bool = true
    var allowsMainWindow: Bool = true

    override var canBecomeKey: Bool { allowsKeyWindow }
    override var canBecomeMain: Bool { allowsMainWindow }
    override var isKeyWindow: Bool { allowsKeyWindow }
    override var isMainWindow: Bool { allowsMainWindow }
}
