import SwiftUI
internal import AppKit

struct NotchMouseSwipeModifier: ViewModifier {
    @ObservedObject var notchViewModel: NotchViewModel
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content.background(
            NotchMouseSwipeMonitorRepresentable(
                canSwipeUp: isEnabled && notchViewModel.canDismissWithMouseDrag,
                canSwipeDown: isEnabled && notchViewModel.canRestoreWithMouseDrag,
                canSwipeHorizontal: isEnabled && notchViewModel.canDismissWithHorizontalMouseDrag,
                onSwipeUp: {
                    notchViewModel.dismissActiveContent()
                },
                onSwipeDown: {
                    notchViewModel.restoreDismissedContent()
                },
                onSwipeHorizontal: {
                    notchViewModel.dismissActiveContent()
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
    let canSwipeHorizontal: Bool
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void
    let onSwipeHorizontal: () -> Void
    let onSwipeStretchChanged: (SwipeInteraction, CGFloat) -> Void
    let onSwipeStretchReset: () -> Void

    func makeNSView(context: Context) -> NotchMouseSwipeMonitorView {
        let view = NotchMouseSwipeMonitorView()
        view.update(
            canSwipeUp: canSwipeUp,
            canSwipeDown: canSwipeDown,
            canSwipeHorizontal: canSwipeHorizontal,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown,
            onSwipeHorizontal: onSwipeHorizontal,
            onSwipeStretchChanged: onSwipeStretchChanged,
            onSwipeStretchReset: onSwipeStretchReset
        )
        return view
    }

    func updateNSView(_ nsView: NotchMouseSwipeMonitorView, context: Context) {
        nsView.update(
            canSwipeUp: canSwipeUp,
            canSwipeDown: canSwipeDown,
            canSwipeHorizontal: canSwipeHorizontal,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown,
            onSwipeHorizontal: onSwipeHorizontal,
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
        static let verticalThreshold: CGFloat = 60
        static let horizontalThreshold: CGFloat = 60
        static let directionDominanceMultiplier: CGFloat = 1.15
        static let lockThreshold: CGFloat = 3
    }

    private var mouseDownMonitor: Any?
    private var mouseDraggedMonitor: Any?
    private var mouseUpMonitor: Any?
    private var keyDownMonitor: Any?
    private var globalKeyDownMonitor: Any?

    private var canSwipeUp = false
    private var canSwipeDown = false
    private var canSwipeHorizontal = false
    private var onSwipeUp: (() -> Void)?
    private var onSwipeDown: (() -> Void)?
    private var onSwipeHorizontal: (() -> Void)?
    private var onSwipeStretchChanged: ((SwipeInteraction, CGFloat) -> Void)?
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
        canSwipeHorizontal: Bool,
        onSwipeUp: @escaping () -> Void,
        onSwipeDown: @escaping () -> Void,
        onSwipeHorizontal: @escaping () -> Void,
        onSwipeStretchChanged: @escaping (SwipeInteraction, CGFloat) -> Void,
        onSwipeStretchReset: @escaping () -> Void
    ) {
        self.canSwipeUp = canSwipeUp
        self.canSwipeDown = canSwipeDown
        self.canSwipeHorizontal = canSwipeHorizontal
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
        self.onSwipeHorizontal = onSwipeHorizontal
        self.onSwipeStretchChanged = onSwipeStretchChanged
        self.onSwipeStretchReset = onSwipeStretchReset

        if !canSwipeUp && !canSwipeDown && !canSwipeHorizontal {
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

        if let keyDownMonitor {
            NSEvent.removeMonitor(keyDownMonitor)
        }

        if let globalKeyDownMonitor {
            NSEvent.removeMonitor(globalKeyDownMonitor)
        }

        mouseDownMonitor = nil
        mouseDraggedMonitor = nil
        mouseUpMonitor = nil
        keyDownMonitor = nil
        globalKeyDownMonitor = nil
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

        if keyDownMonitor == nil {
            keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if self?.handleKeyDown(event) == true {
                    return nil
                }
                return event
            }
        }

        if globalKeyDownMonitor == nil {
            globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                _ = self?.handleKeyDown(event)
            }
        }
    }

    func handleKeyDown(_ event: NSEvent) -> Bool {
        guard canSwipeHorizontal else { return false }
        guard event.keyCode == 123 || event.keyCode == 124 else { return false }

        let screenLocation = NSEvent.mouseLocation
        let isInsideNotch = currentScreenRect()?.contains(screenLocation) == true
        let isKeyWindow = window?.isKeyWindow == true
        guard isInsideNotch || isKeyWindow else { return false }

        DispatchQueue.main.async { [weak self] in
            self?.onSwipeStretchChanged?(.horizontalDismiss, 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                self?.onSwipeHorizontal?()
                self?.onSwipeStretchReset?()
            }
        }
        return true
    }

    func handleMouseDown(_ event: NSEvent) {
        guard canSwipeUp || canSwipeDown || canSwipeHorizontal else {
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

        if canSwipeDown, isRestoreTranslation(translation) {
            DispatchQueue.main.async { [weak self] in
                self?.onSwipeDown?()
            }
            return
        }

        let upwardDistance = max(0, translation.height)
        let horizontalDistance = abs(translation.width)
        let isSimultaneousDismiss = canSwipeHorizontal && canSwipeUp && (
            (upwardDistance / SwipeMetrics.verticalThreshold) + (horizontalDistance / SwipeMetrics.horizontalThreshold) >= 1.2
        )

        if canSwipeHorizontal, isHorizontalDismissTranslation(translation) || isSimultaneousDismiss {
            DispatchQueue.main.async { [weak self] in
                self?.onSwipeHorizontal?()
            }
            return
        }

        if canSwipeUp, isDismissTranslation(translation) {
            DispatchQueue.main.async { [weak self] in
                self?.onSwipeUp?()
            }
            return
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
        let upwardDistance = max(0, translation.height)
        let downwardDistance = max(0, -translation.height)
        let horizontalDistance = abs(translation.width)

        let effectiveUpward = max(0, upwardDistance - SwipeMetrics.lockThreshold)
        let effectiveDownward = max(0, downwardDistance - SwipeMetrics.lockThreshold)
        let effectiveVerticalThreshold = max(1, SwipeMetrics.verticalThreshold - SwipeMetrics.lockThreshold)

        let effectiveHorizontal = max(0, horizontalDistance - SwipeMetrics.lockThreshold)
        let effectiveHorizontalThreshold = max(1, SwipeMetrics.horizontalThreshold - SwipeMetrics.lockThreshold)

        let upwardProgress = canSwipeUp ? min(1.5, effectiveUpward / effectiveVerticalThreshold) : 0
        let downwardProgress = canSwipeDown ? min(1.5, effectiveDownward / effectiveVerticalThreshold) : 0
        let horizontalProgress = canSwipeHorizontal ? min(1.5, effectiveHorizontal / effectiveHorizontalThreshold) : 0

        // 1. Downward (restore)
        if downwardProgress > 0, downwardProgress >= upwardProgress, downwardProgress > horizontalProgress {
            onSwipeStretchChanged?(.restore, downwardProgress)
            return
        }

        // 2. Both upward and horizontal active (simultaneous dismiss)
        if upwardProgress > 0 && horizontalProgress > 0 {
            onSwipeStretchChanged?(
                .simultaneousDismiss(verticalProgress: upwardProgress, horizontalProgress: horizontalProgress),
                max(upwardProgress, horizontalProgress)
            )
            return
        }

        // 3. Only upward
        if upwardProgress > 0 {
            onSwipeStretchChanged?(.dismiss, upwardProgress)
            return
        }

        // 4. Only horizontal
        if horizontalProgress > 0 {
            onSwipeStretchChanged?(.horizontalDismiss, horizontalProgress)
            return
        }

        onSwipeStretchReset?()
    }

    func isHorizontalDismissTranslation(_ translation: CGSize) -> Bool {
        let horizontalDistance = abs(translation.width)
        return horizontalDistance >= SwipeMetrics.horizontalThreshold
    }

    func isDismissTranslation(_ translation: CGSize) -> Bool {
        return translation.height >= SwipeMetrics.verticalThreshold
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
