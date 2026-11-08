import SwiftUI
internal import AppKit

struct NotchMouseSwipeModifier: ViewModifier {
    @ObservedObject var notchViewModel: NotchViewModel
    let isEnabled: Bool

    func body(content: Content) -> some View {
        let stretchEnabled = isEnabled && notchViewModel.isMouseDragStretchEnabled
        let isExpanded = notchViewModel.isExpandedPresentation
        content.background(
            NotchMouseSwipeMonitorRepresentable(
                canSwipeUp: stretchEnabled && isExpanded,
                canSwipeDown: stretchEnabled && isExpanded,
                canSwipeHorizontal: stretchEnabled,
                canTriggerDismiss: isEnabled && notchViewModel.canDismissWithMouseDrag,
                canTriggerRestore: isEnabled && notchViewModel.canRestoreDismissedContent,
                isScrubbingContent: notchViewModel.isScrubbingContent,
                onSwipeUp: {
                    notchViewModel.dismissActiveContent()
                },
                onSwipeDown: {
                    if notchViewModel.canRestoreDismissedContent {
                        notchViewModel.restoreDismissedContent()
                    }
                },
                onSwipeHorizontalDismiss: {
                    notchViewModel.dismissActiveContent()
                },
                onSwipeHorizontalRestore: {
                    if notchViewModel.canRestoreDismissedContent {
                        notchViewModel.restoreDismissedContent()
                    }
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
    let canTriggerDismiss: Bool
    let canTriggerRestore: Bool
    let isScrubbingContent: Bool
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void
    let onSwipeHorizontalDismiss: () -> Void
    let onSwipeHorizontalRestore: () -> Void
    let onSwipeStretchChanged: (SwipeInteraction, CGFloat) -> Void
    let onSwipeStretchReset: () -> Void

    func makeNSView(context: Context) -> NotchMouseSwipeMonitorView {
        let view = NotchMouseSwipeMonitorView()
        view.update(
            canSwipeUp: canSwipeUp,
            canSwipeDown: canSwipeDown,
            canSwipeHorizontal: canSwipeHorizontal,
            canTriggerDismiss: canTriggerDismiss,
            canTriggerRestore: canTriggerRestore,
            isScrubbingContent: isScrubbingContent,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown,
            onSwipeHorizontalDismiss: onSwipeHorizontalDismiss,
            onSwipeHorizontalRestore: onSwipeHorizontalRestore,
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
            canTriggerDismiss: canTriggerDismiss,
            canTriggerRestore: canTriggerRestore,
            isScrubbingContent: isScrubbingContent,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown,
            onSwipeHorizontalDismiss: onSwipeHorizontalDismiss,
            onSwipeHorizontalRestore: onSwipeHorizontalRestore,
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
    private var canTriggerDismiss = false
    private var canTriggerRestore = false
    private var isScrubbingContent = false
    private var onSwipeUp: (() -> Void)?
    private var onSwipeDown: (() -> Void)?
    private var onSwipeHorizontalDismiss: (() -> Void)?
    private var onSwipeHorizontalRestore: (() -> Void)?
    private var onSwipeStretchChanged: ((SwipeInteraction, CGFloat) -> Void)?
    private var onSwipeStretchReset: (() -> Void)?

    private var isTrackingDrag = false
    private var initialScreenLocation: NSPoint?
    private var isDragOnRightSide = true

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
        canTriggerDismiss: Bool,
        canTriggerRestore: Bool,
        isScrubbingContent: Bool,
        onSwipeUp: @escaping () -> Void,
        onSwipeDown: @escaping () -> Void,
        onSwipeHorizontalDismiss: @escaping () -> Void,
        onSwipeHorizontalRestore: @escaping () -> Void,
        onSwipeStretchChanged: @escaping (SwipeInteraction, CGFloat) -> Void,
        onSwipeStretchReset: @escaping () -> Void
    ) {
        self.canSwipeUp = canSwipeUp
        self.canSwipeDown = canSwipeDown
        self.canSwipeHorizontal = canSwipeHorizontal
        self.canTriggerDismiss = canTriggerDismiss
        self.canTriggerRestore = canTriggerRestore
        self.isScrubbingContent = isScrubbingContent
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
        self.onSwipeHorizontalDismiss = onSwipeHorizontalDismiss
        self.onSwipeHorizontalRestore = onSwipeHorizontalRestore
        self.onSwipeStretchChanged = onSwipeStretchChanged
        self.onSwipeStretchReset = onSwipeStretchReset

        if isScrubbingContent || (!canSwipeUp && !canSwipeDown && !canSwipeHorizontal) {
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
        let notchRect = currentScreenRect()
        let isInsideNotch = notchRect?.contains(screenLocation) == true
        let isKeyWindow = window?.isKeyWindow == true
        guard isInsideNotch || isKeyWindow else { return false }

        let isRightSide = (notchRect != nil) ? (screenLocation.x >= notchRect!.midX) : true
        let isOutward = isRightSide ? (event.keyCode == 124) : (event.keyCode == 123)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if isOutward {
                self.onSwipeStretchChanged?(.horizontalExpand, 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    if self.canTriggerRestore {
                        self.onSwipeHorizontalRestore?()
                    }
                    self.onSwipeStretchReset?()
                }
            } else {
                self.onSwipeStretchChanged?(.horizontalDismiss, 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    if self.canTriggerDismiss {
                        self.onSwipeHorizontalDismiss?()
                    }
                    self.onSwipeStretchReset?()
                }
            }
        }
        return true
    }

    func handleMouseDown(_ event: NSEvent) {
        guard canSwipeUp || canSwipeDown || canSwipeHorizontal else {
            resetTracking()
            return
        }

        guard !isScrubbingContent else {
            resetTracking()
            return
        }

        let screenLocation = screenLocation(for: event)
        let notchRect = currentScreenRect()
        let isInsideNotch = notchRect?.contains(screenLocation) == true

        if isInsideNotch, let notchRect {
            isTrackingDrag = true
            initialScreenLocation = screenLocation
            isDragOnRightSide = screenLocation.x >= notchRect.midX
        } else {
            resetTracking()
        }
    }

    func handleMouseDragged(_ event: NSEvent) {
        guard !isScrubbingContent else {
            resetTracking()
            return
        }
        guard isTrackingDrag, let initialScreenLocation else { return }

        let currentLocation = screenLocation(for: event)
        let translation = CGSize(
            width: currentLocation.x - initialScreenLocation.x,
            height: currentLocation.y - initialScreenLocation.y
        )

        updateStretchProgress(for: translation)
    }

    func handleMouseUp(_ event: NSEvent) {
        guard !isScrubbingContent else {
            resetTracking()
            return
        }
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

        if canTriggerRestore, canSwipeDown, isRestoreTranslation(translation) {
            DispatchQueue.main.async { [weak self] in
                self?.onSwipeDown?()
            }
            return
        }

        let outwardTranslation = isDragOnRightSide ? translation.width : -translation.width
        let isHorizontalExpand = outwardTranslation >= SwipeMetrics.horizontalThreshold
        if canTriggerRestore, canSwipeHorizontal, isHorizontalExpand {
            DispatchQueue.main.async { [weak self] in
                self?.onSwipeHorizontalRestore?()
            }
            return
        }

        let upwardDistance = max(0, translation.height)
        let inwardTranslation = isDragOnRightSide ? -translation.width : translation.width
        let inwardDistance = max(0, inwardTranslation)
        let isSimultaneousDismiss = canSwipeHorizontal && canSwipeUp && (
            (upwardDistance / SwipeMetrics.verticalThreshold) + (inwardDistance / SwipeMetrics.horizontalThreshold) >= 1.2
        )

        if canTriggerDismiss, canSwipeHorizontal, isHorizontalDismissTranslation(translation) || isSimultaneousDismiss {
            DispatchQueue.main.async { [weak self] in
                self?.onSwipeHorizontalDismiss?()
            }
            return
        }

        if canTriggerDismiss, canSwipeUp, isDismissTranslation(translation) {
            DispatchQueue.main.async { [weak self] in
                self?.onSwipeUp?()
            }
            return
        }
    }

    func screenLocation(for event: NSEvent) -> NSPoint {
        NSEvent.mouseLocation
    }

    func currentScreenRect() -> CGRect? {
        guard let window else { return nil }

        let rectInWindow = convert(bounds, to: nil)
        let screenRect = window.convertToScreen(rectInWindow)
        return CGRect(
            x: screenRect.minX,
            y: screenRect.minY,
            width: screenRect.width,
            height: screenRect.height + 4
        )
    }

    func updateStretchProgress(for translation: CGSize) {
        let upwardDistance = max(0, translation.height)
        let downwardDistance = max(0, -translation.height)
        
        let outwardTranslation = isDragOnRightSide ? translation.width : -translation.width
        let outwardDistance = max(0, outwardTranslation)
        let inwardDistance = max(0, -outwardTranslation)

        let effectiveUpward = max(0, upwardDistance - SwipeMetrics.lockThreshold)
        let effectiveDownward = max(0, downwardDistance - SwipeMetrics.lockThreshold)
        let effectiveVerticalThreshold = max(1, SwipeMetrics.verticalThreshold - SwipeMetrics.lockThreshold)

        let effectiveInward = max(0, inwardDistance - SwipeMetrics.lockThreshold)
        let effectiveOutward = max(0, outwardDistance - SwipeMetrics.lockThreshold)
        let effectiveHorizontalThreshold = max(1, SwipeMetrics.horizontalThreshold - SwipeMetrics.lockThreshold)

        let upwardProgress = canSwipeUp ? min(1.5, effectiveUpward / effectiveVerticalThreshold) : 0
        let downwardProgress = canSwipeDown ? min(1.5, effectiveDownward / effectiveVerticalThreshold) : 0
        let inwardProgress = canSwipeHorizontal ? min(1.5, effectiveInward / effectiveHorizontalThreshold) : 0
        let outwardProgress = canSwipeHorizontal ? min(1.5, effectiveOutward / effectiveHorizontalThreshold) : 0

        let vProgress: CGFloat
        let vDirection: VerticalSwipeDirection?
        if downwardProgress > 0 && downwardProgress >= upwardProgress {
            vProgress = downwardProgress
            vDirection = .down
        } else if upwardProgress > 0 {
            vProgress = upwardProgress
            vDirection = .up
        } else {
            vProgress = 0
            vDirection = nil
        }

        let hProgress: CGFloat
        let hDirection: HorizontalSwipeDirection?
        if inwardProgress > 0 && inwardProgress >= outwardProgress {
            hProgress = inwardProgress
            hDirection = .inward
        } else if outwardProgress > 0 {
            hProgress = outwardProgress
            hDirection = .outward
        } else {
            hProgress = 0
            hDirection = nil
        }

        // Both active: combined 2D swipe!
        if let vDirection, vProgress > 0, let hDirection, hProgress > 0 {
            if vDirection == .up && hDirection == .inward {
                onSwipeStretchChanged?(
                    .simultaneousDismiss(verticalProgress: vProgress, horizontalProgress: hProgress),
                    max(vProgress, hProgress)
                )
            } else {
                onSwipeStretchChanged?(
                    .combined(
                        verticalDirection: vDirection,
                        verticalProgress: vProgress,
                        horizontalDirection: hDirection,
                        horizontalProgress: hProgress
                    ),
                    max(vProgress, hProgress)
                )
            }
            return
        }

        // Only vertical active
        if let vDirection, vProgress > 0 {
            if vDirection == .down {
                onSwipeStretchChanged?(.restore, vProgress)
            } else {
                onSwipeStretchChanged?(.dismiss, vProgress)
            }
            return
        }

        // Only horizontal active
        if let hDirection, hProgress > 0 {
            if hDirection == .inward {
                onSwipeStretchChanged?(.horizontalDismiss, hProgress)
            } else {
                onSwipeStretchChanged?(.horizontalExpand, hProgress)
            }
            return
        }

        onSwipeStretchReset?()
    }

    func isHorizontalDismissTranslation(_ translation: CGSize) -> Bool {
        let inwardTranslation = isDragOnRightSide ? -translation.width : translation.width
        return inwardTranslation >= SwipeMetrics.horizontalThreshold
    }

    func isDismissTranslation(_ translation: CGSize) -> Bool {
        return translation.height >= SwipeMetrics.verticalThreshold
    }

    func isRestoreTranslation(_ translation: CGSize) -> Bool {
        return translation.height <= -SwipeMetrics.verticalThreshold
    }

    func resetTracking() {
        isTrackingDrag = false
        initialScreenLocation = nil
        isDragOnRightSide = true
        onSwipeStretchReset?()
    }
}
