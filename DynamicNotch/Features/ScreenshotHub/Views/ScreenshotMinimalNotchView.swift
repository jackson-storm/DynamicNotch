import SwiftUI
internal import AppKit

struct ScreenshotNotchView: View {
    @ObservedObject var screenshotViewModel: ScreenshotViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering: Bool = false
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            screenshot
        }
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16)) {
                isHovering = hovering
            }
        }
        .padding(.horizontal, isDynamicIsland ? 10 : 36)
        .padding(.bottom, isDynamicIsland ? 10 : 10)
    }
    
    private var screenshot: some View {
        VStack {
            if let screenshot = screenshotViewModel.activeScreenshot {
                ZStack(alignment: .topTrailing) {
                    screenshotPreview(screenshot)

                    dragHint
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(10)
                        .allowsHitTesting(false)
                    
                    buttons
                        .opacity(isHovering && !isDragging ? 1 : 0)
                        .allowsHitTesting(isHovering && !isDragging)
                }
                .frame(height: 145)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(isHovering ? 0.14 : 0.07), lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.24), radius: 10, y: 5)
            }
        }
    }

    private func screenshotPreview(_ screenshot: ScreenshotModel) -> some View {
        Image(nsImage: screenshot.image)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                ScreenshotDragSourceView(
                    screenshot: screenshot,
                    makePasteboardWriter: {
                        screenshotViewModel.beginDragging(screenshot: screenshot)
                    },
                    onOpen: {
                        screenshotViewModel.openEditingWindow()
                    },
                    onDragStateChange: { dragging in
                        isDragging = dragging
                    },
                    onDragCompleted: { didDrop in
                        screenshotViewModel.finishDragging(
                            screenshotID: screenshot.id,
                            didDrop: didDrop
                        )
                    }
                )
                .accessibilityLabel("Screenshot preview")
                .accessibilityHint("Click to open, or drag to another app or folder")
            }
    }

    private var dragHint: some View {
        Label(isDragging ? "Drop anywhere" : "Drag anywhere", systemImage: isDragging ? "hand.closed.fill" : "hand.draw.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 9)
            .frame(height: 24)
            .background(.black.opacity(0.56), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .opacity(isHovering || isDragging ? 1 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isHovering)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isDragging)
    }
    
    private var buttons: some View {
        VStack(spacing: 10) {
            Button(action: { screenshotViewModel.deleteScreenshot() }) {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .stroke(.white.opacity(0.08))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
            
            Button(action: { screenshotViewModel.copyImageToClipboard() }) {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .stroke(.white.opacity(0.08))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "document.on.document.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
            
            Button(action: { screenshotViewModel.showInFinder() }) {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .stroke(.white.opacity(0.08))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
        }
        .padding(8)
        .buttonStyle(.plain)
    }
}

private struct ScreenshotDragSourceView: NSViewRepresentable {
    let screenshot: ScreenshotModel
    let makePasteboardWriter: () -> NSPasteboardWriting?
    let onOpen: () -> Void
    let onDragStateChange: (Bool) -> Void
    let onDragCompleted: (Bool) -> Void

    func makeNSView(context: Context) -> ScreenshotDragSourceNSView {
        let view = ScreenshotDragSourceNSView()
        update(view)
        return view
    }

    func updateNSView(_ nsView: ScreenshotDragSourceNSView, context: Context) {
        update(nsView)
    }

    private func update(_ view: ScreenshotDragSourceNSView) {
        view.screenshotImage = screenshot.image
        view.makePasteboardWriter = makePasteboardWriter
        view.onOpen = onOpen
        view.onDragStateChange = onDragStateChange
        view.onDragCompleted = onDragCompleted
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.button)
        view.setAccessibilityLabel("Screenshot preview")
        view.setAccessibilityHelp("Click to open, or drag to another app or folder")
    }
}

private final class ScreenshotDragSourceNSView: NSView, NSDraggingSource {
    var screenshotImage: NSImage?
    var makePasteboardWriter: () -> NSPasteboardWriting? = { nil }
    var onOpen: () -> Void = {}
    var onDragStateChange: (Bool) -> Void = { _ in }
    var onDragCompleted: (Bool) -> Void = { _ in }

    private var mouseDownEvent: NSEvent?
    private var didBeginDragging = false

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: didBeginDragging ? .closedHand : .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
        didBeginDragging = false
        window?.makeFirstResponder(self)
    }

    override func mouseDragged(with event: NSEvent) {
        guard !didBeginDragging, let mouseDownEvent else { return }

        let startPoint = convert(mouseDownEvent.locationInWindow, from: nil)
        let currentPoint = convert(event.locationInWindow, from: nil)
        guard hypot(currentPoint.x - startPoint.x, currentPoint.y - startPoint.y) >= 3 else {
            return
        }

        beginDragging(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if !didBeginDragging {
            onOpen()
        }

        if !didBeginDragging {
            resetInteraction()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 49 || event.keyCode == 76 {
            onOpen()
        } else {
            super.keyDown(with: event)
        }
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        let didDrop = !operation.isEmpty
        onDragStateChange(false)
        onDragCompleted(didDrop)
        resetInteraction()
    }

    func ignoreModifierKeys(for session: NSDraggingSession) -> Bool {
        true
    }

    private func beginDragging(with event: NSEvent) {
        guard let writer = makePasteboardWriter() else {
            resetInteraction()
            return
        }

        didBeginDragging = true
        onDragStateChange(true)
        window?.invalidateCursorRects(for: self)

        let draggingItem = NSDraggingItem(pasteboardWriter: writer)
        draggingItem.setDraggingFrame(draggingFrame(at: event), contents: draggingImage())

        let session = beginDraggingSession(with: [draggingItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
        mouseDownEvent = nil
    }

    private func draggingFrame(at event: NSEvent) -> NSRect {
        let point = convert(event.locationInWindow, from: nil)
        let previewSize = fittedPreviewSize(maximumDimension: 128)

        return NSRect(
            x: point.x - previewSize.width / 2,
            y: point.y - previewSize.height / 2,
            width: previewSize.width,
            height: previewSize.height
        )
    }

    private func draggingImage() -> NSImage? {
        guard let screenshotImage else { return nil }

        let previewSize = fittedPreviewSize(maximumDimension: 128)
        let preview = NSImage(size: previewSize)
        preview.lockFocus()
        screenshotImage.draw(
            in: NSRect(origin: .zero, size: previewSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 0.96,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high]
        )
        preview.unlockFocus()
        return preview
    }

    private func fittedPreviewSize(maximumDimension: CGFloat) -> NSSize {
        guard let screenshotImage,
              screenshotImage.size.width > 0,
              screenshotImage.size.height > 0 else {
            return NSSize(width: maximumDimension, height: maximumDimension * 0.65)
        }

        let scale = min(
            maximumDimension / screenshotImage.size.width,
            maximumDimension / screenshotImage.size.height,
            1
        )
        return NSSize(
            width: max(40, screenshotImage.size.width * scale),
            height: max(32, screenshotImage.size.height * scale)
        )
    }

    private func resetInteraction() {
        mouseDownEvent = nil
        didBeginDragging = false
        if let window {
            window.invalidateCursorRects(for: self)
        }
    }
}
