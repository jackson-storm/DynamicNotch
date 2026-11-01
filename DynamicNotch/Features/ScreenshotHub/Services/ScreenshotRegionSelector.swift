internal import AppKit

struct ScreenshotCaptureTarget {
    let displayID: CGDirectDisplayID
    let frame: CGRect
    let scale: CGFloat
    let selection: CGRect?

    init?(screen: NSScreen, selection: CGRect? = nil) {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return nil }
        displayID = number.uint32Value
        frame = screen.frame
        scale = screen.backingScaleFactor
        self.selection = selection
    }
}

@MainActor
final class ScreenshotRegionSelector {
    private var panels: [RegionSelectionPanel] = []
    private var continuation: CheckedContinuation<ScreenshotCaptureTarget?, Never>?

    func select() async -> ScreenshotCaptureTarget? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            guard !NSScreen.screens.isEmpty else { finish(nil); return }
            for screen in NSScreen.screens {
                let panel = RegionSelectionPanel(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
                panel.isReleasedWhenClosed = false
                panel.backgroundColor = .clear
                panel.isOpaque = false
                panel.hasShadow = false
                panel.level = .screenSaver
                panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
                let view = RegionSelectionView(frame: CGRect(origin: .zero, size: screen.frame.size))
                view.onFinish = { [weak self] rect in
                    self?.finish(rect.flatMap { ScreenshotCaptureTarget(screen: screen, selection: $0) })
                }
                panel.contentView = view
                panel.makeFirstResponder(view)
                panels.append(panel)
                panel.orderFrontRegardless()
            }
            NSApp.activate()
            let pointer = NSEvent.mouseLocation
            panels.first(where: { $0.frame.contains(pointer) })?.makeKey()
        }
    }

    private func finish(_ target: ScreenshotCaptureTarget?) {
        guard let continuation else { return }
        self.continuation = nil
        panels.forEach { $0.orderOut(nil); $0.close() }
        panels = []
        continuation.resume(returning: target)
    }
}

private final class RegionSelectionPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

private final class RegionSelectionView: NSView {
    var onFinish: ((CGRect?) -> Void)?
    private var anchor: CGPoint?
    private var selection: CGRect = .zero
    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(self)
        anchor = convert(event.locationInWindow, from: nil)
        selection = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let anchor else { return }
        let point = convert(event.locationInWindow, from: nil)
        selection = CGRect(x: min(anchor.x, point.x), y: min(anchor.y, point.y), width: abs(point.x - anchor.x), height: abs(point.y - anchor.y)).intersection(bounds)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        mouseDragged(with: event)
        guard selection.width >= 2, selection.height >= 2, let window else { onFinish?(nil); return }
        onFinish?(window.convertToScreen(selection))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onFinish?(nil) }
    }

    override func cancelOperation(_ sender: Any?) { onFinish?(nil) }
    override func rightMouseDown(with event: NSEvent) { onFinish?(nil) }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.20).setFill()
        bounds.fill()
        guard !selection.isEmpty else { return }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current?.compositingOperation = .clear
        selection.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSColor.white.setStroke()
        let border = NSBezierPath(rect: selection.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()
        let scale = window?.screen?.backingScaleFactor ?? 1
        let dimensions = "\(Int(selection.width * scale)) × \(Int(selection.height * scale))"
        let text = NSAttributedString(string: dimensions, attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium), .foregroundColor: NSColor.white])
        text.draw(at: CGPoint(x: selection.minX + 6, y: max(8, selection.minY - 20)))
    }
}
