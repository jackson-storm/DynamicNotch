import SwiftUI
internal import AppKit

struct NotchMouseSwipeModifier: ViewModifier {
    @ObservedObject var notchViewModel: NotchViewModel

    func body(content: Content) -> some View {
        content.background(
            NotchMouseSwipeMonitorRepresentable(
                canSwipeUp: notchViewModel.notchModel.content != nil,
                canSwipeDown: notchViewModel.canRestoreDismissedContent,
                onSwipeUp: {
                    notchViewModel.dismissActiveContent()
                },
                onSwipeDown: {
                    notchViewModel.restoreDismissedContent()
                },
                onSwipeStretchChanged: { interaction, progress in
                    notchViewModel.updateSwipeStretch(for: interaction, progress: progress)
                },
                onSwipeStretchReset: {
                    notchViewModel.resetSwipeStretch()
                }
            )
        )
    }
}

private struct NotchMouseSwipeMonitorRepresentable: NSViewRepresentable {
    let canSwipeUp: Bool
    let canSwipeDown: Bool
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void
    let onSwipeStretchChanged: (NotchSwipeInteraction, CGFloat) -> Void
    let onSwipeStretchReset: () -> Void

    func makeNSView(context: Context) -> NotchMouseSwipeMonitorView {
        let view = NotchMouseSwipeMonitorView()
        view.update(
            canSwipeUp: canSwipeUp,
            canSwipeDown: canSwipeDown,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown,
            onSwipeStretchChanged: onSwipeStretchChanged,
            onSwipeStretchReset: onSwipeStretchReset
        )
        return view
    }

    func updateNSView(_ nsView: NotchMouseSwipeMonitorView, context: Context) {
        nsView.update(
            canSwipeUp: canSwipeUp,
            canSwipeDown: canSwipeDown,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown,
            onSwipeStretchChanged: onSwipeStretchChanged,
            onSwipeStretchReset: onSwipeStretchReset
        )
    }

    static func dismantleNSView(_ nsView: NotchMouseSwipeMonitorView, coordinator: ()) {
        nsView.stopMonitoring()
    }
}

private final class NotchMouseSwipeMonitorView: NSView {
    private enum SwipeMetrics {
        static let verticalThreshold: CGFloat = 42
        static let directionDominanceMultiplier: CGFloat = 1.15
    }

    private var mouseDownMonitor: Any?
    private var mouseDraggedMonitor: Any?
    private var mouseUpMonitor: Any?

    private var canSwipeUp = false
    private var canSwipeDown = false
    private var onSwipeUp: (() -> Void)?
    private var onSwipeDown: (() -> Void)?
    private var onSwipeStretchChanged: ((NotchSwipeInteraction, CGFloat) -> Void)?
    private var onSwipeStretchReset: (() -> Void)?

    private var isTrackingDrag = false
    private var initialScreenLocation: NSPoint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        installMonitorsIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopMonitoring()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        installMonitorsIfNeeded()
    }

    func update(
        canSwipeUp: Bool,
        canSwipeDown: Bool,
        onSwipeUp: @escaping () -> Void,
        onSwipeDown: @escaping () -> Void,
        onSwipeStretchChanged: @escaping (NotchSwipeInteraction, CGFloat) -> Void,
        onSwipeStretchReset: @escaping () -> Void
    ) {
        self.canSwipeUp = canSwipeUp
        self.canSwipeDown = canSwipeDown
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
        self.onSwipeStretchChanged = onSwipeStretchChanged
        self.onSwipeStretchReset = onSwipeStretchReset

        if !canSwipeUp && !canSwipeDown {
            resetTracking()
        }
    }

    func stopMonitoring() {
        if let mouseDownMonitor {
            NSEvent.removeMonitor(mouseDownMonitor)
        }

        if let mouseDraggedMonitor {
            NSEvent.removeMonitor(mouseDraggedMonitor)
        }

        if let mouseUpMonitor {
            NSEvent.removeMonitor(mouseUpMonitor)
        }

        mouseDownMonitor = nil
        mouseDraggedMonitor = nil
        mouseUpMonitor = nil
        resetTracking()
    }
}

private extension NotchMouseSwipeMonitorView {
    func installMonitorsIfNeeded() {
        if mouseDownMonitor == nil {
            mouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                self?.handleMouseDown(event)
                return event
            }
        }

        if mouseDraggedMonitor == nil {
            mouseDraggedMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
                self?.handleMouseDragged(event)
                return event
            }
        }

        if mouseUpMonitor == nil {
            mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
                self?.handleMouseUp(event)
                return event
            }
        }
    }

    func handleMouseDown(_ event: NSEvent) {
        guard canSwipeUp || canSwipeDown else {
            resetTracking()
            return
        }

        let screenLocation = screenLocation(for: event)
        let isInsideNotch = currentScreenRect()?.contains(screenLocation) == true

        if isInsideNotch {
            isTrackingDrag = true
            initialScreenLocation = screenLocation
        } else {
            resetTracking()
        }
    }

    func handleMouseDragged(_ event: NSEvent) {
        guard isTrackingDrag, let initialScreenLocation else { return }

        let currentLocation = screenLocation(for: event)
        let translation = CGSize(
            width: currentLocation.x - initialScreenLocation.x,
            height: currentLocation.y - initialScreenLocation.y
        )

        updateStretchProgress(for: translation)
    }

    func handleMouseUp(_ event: NSEvent) {
        guard isTrackingDrag, let initialScreenLocation else {
            resetTracking()
            return
        }

        let currentLocation = screenLocation(for: event)
        let translation = CGSize(
            width: currentLocation.x - initialScreenLocation.x,
            height: currentLocation.y - initialScreenLocation.y
        )

        defer {
            resetTracking()
        }

        if canSwipeUp, isDismissTranslation(translation) {
            DispatchQueue.main.async { [weak self] in
                self?.onSwipeUp?()
            }
            return
        }

        if canSwipeDown, isRestoreTranslation(translation) {
            DispatchQueue.main.async { [weak self] in
                self?.onSwipeDown?()
            }
        }
    }

    func screenLocation(for event: NSEvent) -> NSPoint {
        if let window = event.window {
            return window.convertToScreen(
                NSRect(origin: event.locationInWindow, size: .zero)
            ).origin
        }

        return NSEvent.mouseLocation
    }

    func currentScreenRect() -> CGRect? {
        guard let window else { return nil }

        let rectInWindow = convert(bounds, to: nil)
        return window.convertToScreen(rectInWindow)
    }

    func updateStretchProgress(for translation: CGSize) {
        let verticalDistance = abs(translation.height)
        let horizontalDistance = abs(translation.width)

        guard verticalDistance > horizontalDistance * SwipeMetrics.directionDominanceMultiplier else {
            onSwipeStretchReset?()
            return
        }

        if translation.height > 0, canSwipeUp {
            let progress = min(verticalDistance / SwipeMetrics.verticalThreshold, 1)
            onSwipeStretchChanged?(.dismiss, progress)
            return
        }

        if translation.height < 0, canSwipeDown {
            let progress = min(verticalDistance / SwipeMetrics.verticalThreshold, 1)
            onSwipeStretchChanged?(.restore, progress)
            return
        }

        onSwipeStretchReset?()
    }

    func isDismissTranslation(_ translation: CGSize) -> Bool {
        let verticalDistance = abs(translation.height)
        let horizontalDistance = abs(translation.width)

        return translation.height >= SwipeMetrics.verticalThreshold &&
        verticalDistance > horizontalDistance * SwipeMetrics.directionDominanceMultiplier
    }

    func isRestoreTranslation(_ translation: CGSize) -> Bool {
        let verticalDistance = abs(translation.height)
        let horizontalDistance = abs(translation.width)

        return translation.height <= -SwipeMetrics.verticalThreshold &&
        verticalDistance > horizontalDistance * SwipeMetrics.directionDominanceMultiplier
    }

    func resetTracking() {
        isTrackingDrag = false
        initialScreenLocation = nil
        onSwipeStretchReset?()
    }
}
