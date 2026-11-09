import SwiftUI
internal import AppKit

struct NotchSwipeDismissModifier: ViewModifier {
    @ObservedObject var notchViewModel: NotchViewModel
    
    let isEnabled: Bool

    func body(content: Content) -> some View {
        let stretchEnabled = isEnabled && notchViewModel.isTrackpadSwipeStretchEnabled
        content.background(
            NotchSwipeDismissMonitorRepresentable(
                canSwipeUp: stretchEnabled,
                canSwipeDown: stretchEnabled,
                canSwipeHorizontal: stretchEnabled,
                canTriggerDismiss: isEnabled && notchViewModel.canDismissWithTrackpadSwipe,
                canTriggerRestore: isEnabled && notchViewModel.canRestoreWithTrackpadSwipe,
                isHoveringScrollableContent: notchViewModel.isHoveringScrollableContent,
                isScrubbingContent: notchViewModel.isScrubbingContent,
                onSwipeUp: {
                    notchViewModel.dismissActiveContent()
                },
                onSwipeDown: {
                    if notchViewModel.canRestoreWithTrackpadSwipe {
                        notchViewModel.restoreDismissedContent()
                    }
                },
                onSwipeHorizontalDismiss: {
                    notchViewModel.dismissActiveContent()
                },
                onSwipeHorizontalRestore: {
                    if notchViewModel.canRestoreWithTrackpadSwipe {
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

private struct NotchSwipeDismissMonitorRepresentable: NSViewRepresentable {
    let canSwipeUp: Bool
    let canSwipeDown: Bool
    let canSwipeHorizontal: Bool
    let canTriggerDismiss: Bool
    let canTriggerRestore: Bool
    let isHoveringScrollableContent: Bool
    let isScrubbingContent: Bool
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void
    let onSwipeHorizontalDismiss: () -> Void
    let onSwipeHorizontalRestore: () -> Void
    let onSwipeStretchChanged: (SwipeInteraction, CGFloat) -> Void
    let onSwipeStretchReset: () -> Void

    func makeNSView(context: Context) -> NotchSwipeDismissMonitorView {
        let view = NotchSwipeDismissMonitorView()
        view.update(
            canSwipeUp: canSwipeUp,
            canSwipeDown: canSwipeDown,
            canSwipeHorizontal: canSwipeHorizontal,
            canTriggerDismiss: canTriggerDismiss,
            canTriggerRestore: canTriggerRestore,
            isHoveringScrollableContent: isHoveringScrollableContent,
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

    func updateNSView(_ nsView: NotchSwipeDismissMonitorView, context: Context) {
        nsView.update(
            canSwipeUp: canSwipeUp,
            canSwipeDown: canSwipeDown,
            canSwipeHorizontal: canSwipeHorizontal,
            canTriggerDismiss: canTriggerDismiss,
            canTriggerRestore: canTriggerRestore,
            isHoveringScrollableContent: isHoveringScrollableContent,
            isScrubbingContent: isScrubbingContent,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown,
            onSwipeHorizontalDismiss: onSwipeHorizontalDismiss,
            onSwipeHorizontalRestore: onSwipeHorizontalRestore,
            onSwipeStretchChanged: onSwipeStretchChanged,
            onSwipeStretchReset: onSwipeStretchReset
        )
    }

    static func dismantleNSView(_ nsView: NotchSwipeDismissMonitorView, coordinator: ()) {
        nsView.stopMonitoring()
    }
}

private final class NotchSwipeDismissMonitorView: NSView {
    private enum SwipeMetrics {
        static let verticalThreshold: CGFloat = 60
        static let horizontalThreshold: CGFloat = 60
        static let directionDominanceMultiplier: CGFloat = 1.25
        static let lockThreshold: CGFloat = 2
    }

    private var localScrollMonitor: Any?
    private var globalScrollMonitor: Any?

    private var canSwipeUp = false
    private var canSwipeDown = false
    private var canSwipeHorizontal = false
    private var canTriggerDismiss = false
    private var canTriggerRestore = false
    private var isHoveringScrollableContent = false
    private var isScrubbingContent = false
    private var onSwipeUp: (() -> Void)?
    private var onSwipeDown: (() -> Void)?
    private var onSwipeHorizontalDismiss: (() -> Void)?
    private var onSwipeHorizontalRestore: (() -> Void)?
    private var onSwipeStretchChanged: ((SwipeInteraction, CGFloat) -> Void)?
    private var onSwipeStretchReset: (() -> Void)?

    private var isTrackingSwipe = false
    private var isGestureActionLocked = false
    private var isSwipeOnRightSide = true
    private var accumulatedUpwardSwipe: CGFloat = 0
    private var accumulatedDownwardSwipe: CGFloat = 0
    private var accumulatedInwardSwipe: CGFloat = 0
    private var accumulatedOutwardSwipe: CGFloat = 0
    private var didTriggerSwipe = false

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
        isHoveringScrollableContent: Bool,
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
        self.isHoveringScrollableContent = isHoveringScrollableContent
        self.isScrubbingContent = isScrubbingContent
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
        self.onSwipeHorizontalDismiss = onSwipeHorizontalDismiss
        self.onSwipeHorizontalRestore = onSwipeHorizontalRestore
        self.onSwipeStretchChanged = onSwipeStretchChanged
        self.onSwipeStretchReset = onSwipeStretchReset

        if isScrubbingContent || isHoveringScrollableContent || (!canSwipeUp && !canSwipeDown && !canSwipeHorizontal) {
            resetSwipeTracking()
        }
    }

    func stopMonitoring() {
        if let localScrollMonitor {
            NSEvent.removeMonitor(localScrollMonitor)
        }

        if let globalScrollMonitor {
            NSEvent.removeMonitor(globalScrollMonitor)
        }

        localScrollMonitor = nil
        globalScrollMonitor = nil
        resetSwipeTracking()
    }
}

private extension NotchSwipeDismissMonitorView {
    func installMonitorsIfNeeded() {
        if localScrollMonitor == nil {
            localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handleLocalScrollEvent(event)
                return event
            }
        }

        if globalScrollMonitor == nil {
            globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handleGlobalScrollEvent(event)
            }
        }
    }

    func handleLocalScrollEvent(_ event: NSEvent) {
        processScrollEvent(event, screenLocation: NSEvent.mouseLocation)
    }

    func handleGlobalScrollEvent(_ event: NSEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.processScrollEvent(event, screenLocation: NSEvent.mouseLocation)
        }
    }

    func processScrollEvent(_ event: NSEvent, screenLocation: NSPoint) {
        guard shouldTrackSwipe(for: event) else {
            resetSwipeTracking()
            return
        }

        let notchRect = currentScreenRect()
        let isInsideNotch = notchRect?.contains(screenLocation) == true

        if event.phase.contains(.mayBegin) || event.phase.contains(.began) {
            resetSwipeTracking()
            isGestureActionLocked = false
            isTrackingSwipe = isInsideNotch
            if let notchRect {
                isSwipeOnRightSide = screenLocation.x >= notchRect.midX
            }
        } else if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
            resetSwipeTracking()
            isGestureActionLocked = false
            return
        } else if isGestureActionLocked {
            return
        } else if !isTrackingSwipe && isInsideNotch {
            isTrackingSwipe = true
            if let notchRect {
                isSwipeOnRightSide = screenLocation.x >= notchRect.midX
            }
        }

        guard isTrackingSwipe else {
            return
        }

        let horizontalDelta = physicalHorizontalDelta(from: event)
        let outwardDelta = isSwipeOnRightSide ? horizontalDelta : -horizontalDelta

        if outwardDelta > 0 {
            accumulatedOutwardSwipe += outwardDelta
            accumulatedInwardSwipe = max(0, accumulatedInwardSwipe - outwardDelta)
        } else {
            accumulatedInwardSwipe += abs(outwardDelta)
            accumulatedOutwardSwipe = max(0, accumulatedOutwardSwipe + outwardDelta)
        }

        let verticalDelta = physicalVerticalDelta(from: event)
        if verticalDelta > 0 {
            accumulatedUpwardSwipe += verticalDelta
            accumulatedDownwardSwipe = max(0, accumulatedDownwardSwipe - verticalDelta)
        } else {
            accumulatedDownwardSwipe += abs(verticalDelta)
            accumulatedUpwardSwipe = max(0, accumulatedUpwardSwipe + verticalDelta)
        }
        
        let effectiveUpward = max(0, accumulatedUpwardSwipe - SwipeMetrics.lockThreshold)
        let effectiveDownward = max(0, accumulatedDownwardSwipe - SwipeMetrics.lockThreshold)
        let effectiveVerticalThreshold = max(1, SwipeMetrics.verticalThreshold - SwipeMetrics.lockThreshold)

        let effectiveInward = max(0, accumulatedInwardSwipe - SwipeMetrics.lockThreshold)
        let effectiveOutward = max(0, accumulatedOutwardSwipe - SwipeMetrics.lockThreshold)
        let effectiveHorizontalThreshold = max(1, SwipeMetrics.horizontalThreshold - SwipeMetrics.lockThreshold)

        let upwardProgress = canSwipeUp
            ? (effectiveUpward / effectiveVerticalThreshold)
            : 0
        let downwardProgress = canSwipeDown
            ? (effectiveDownward / effectiveVerticalThreshold)
            : 0
        let inwardProgress = canSwipeHorizontal
            ? (effectiveInward / effectiveHorizontalThreshold)
            : 0
        let outwardProgress = canSwipeHorizontal
            ? (effectiveOutward / effectiveHorizontalThreshold)
            : 0

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

        // 1. Threshold triggers
        if !didTriggerSwipe {
            // Downward trigger:
            if canTriggerRestore, canSwipeDown, accumulatedDownwardSwipe >= SwipeMetrics.verticalThreshold {
                didTriggerSwipe = true
                isGestureActionLocked = true
                DispatchQueue.main.async { [weak self] in
                    self?.onSwipeDown?()
                }
                resetSwipeTracking()
                return
            }

            // Upward trigger:
            if canTriggerDismiss, canSwipeUp, accumulatedUpwardSwipe >= SwipeMetrics.verticalThreshold {
                didTriggerSwipe = true
                isGestureActionLocked = true
                DispatchQueue.main.async { [weak self] in
                    self?.onSwipeUp?()
                }
                resetSwipeTracking()
                return
            }

            // Horizontal inward dismiss trigger:
            if canTriggerDismiss, canSwipeHorizontal, accumulatedInwardSwipe >= SwipeMetrics.horizontalThreshold {
                didTriggerSwipe = true
                isGestureActionLocked = true
                DispatchQueue.main.async { [weak self] in
                    self?.onSwipeHorizontalDismiss?()
                }
                resetSwipeTracking()
                return
            }

            // Horizontal outward restore trigger:
            if canTriggerRestore, canSwipeHorizontal, accumulatedOutwardSwipe >= SwipeMetrics.horizontalThreshold {
                didTriggerSwipe = true
                isGestureActionLocked = true
                DispatchQueue.main.async { [weak self] in
                    self?.onSwipeHorizontalRestore?()
                }
                resetSwipeTracking()
                return
            }

            // Simultaneous upward + inward dismiss trigger:
            if canTriggerDismiss, canSwipeUp && canSwipeHorizontal && (upwardProgress + inwardProgress >= 1.2) {
                didTriggerSwipe = true
                isGestureActionLocked = true
                DispatchQueue.main.async { [weak self] in
                    self?.onSwipeHorizontalDismiss?()
                }
                resetSwipeTracking()
                return
            }
        }

        // 2. Interactive stretch updates:
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

        // Only vertical active:
        if let vDirection, vProgress > 0 {
            if vDirection == .down {
                onSwipeStretchChanged?(.restore, vProgress)
            } else {
                onSwipeStretchChanged?(.dismiss, vProgress)
            }
            return
        }

        // Only horizontal active:
        if let hDirection, hProgress > 0 {
            if hDirection == .inward {
                onSwipeStretchChanged?(.horizontalDismiss, hProgress)
            } else {
                onSwipeStretchChanged?(.horizontalExpand, hProgress)
            }
            return
        }

        // Neither:
        onSwipeStretchReset?()
    }

    func shouldTrackSwipe(for event: NSEvent) -> Bool {
        guard !isHoveringScrollableContent && !isScrubbingContent else { return false }
        guard canSwipeUp || canSwipeDown || canSwipeHorizontal else { return false }
        guard window != nil else { return false }
        guard event.hasPreciseScrollingDeltas else { return false }
        guard !event.phase.isEmpty else { return false }
        guard event.momentumPhase.isEmpty else { return false }
        return true
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

    func physicalVerticalDelta(from event: NSEvent) -> CGFloat {
        let deltaY = CGFloat(event.scrollingDeltaY)
        return event.isDirectionInvertedFromDevice ? -deltaY : deltaY
    }

    func physicalHorizontalDelta(from event: NSEvent) -> CGFloat {
        let deltaX = CGFloat(event.scrollingDeltaX)
        return event.isDirectionInvertedFromDevice ? deltaX : -deltaX
    }

    func resetSwipeTracking() {
        isTrackingSwipe = false
        isSwipeOnRightSide = true
        accumulatedUpwardSwipe = 0
        accumulatedDownwardSwipe = 0
        accumulatedInwardSwipe = 0
        accumulatedOutwardSwipe = 0
        didTriggerSwipe = false
        onSwipeStretchReset?()
    }
}
