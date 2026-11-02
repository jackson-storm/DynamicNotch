import SwiftUI
internal import AppKit

struct NotchSwipeDismissModifier: ViewModifier {
    @ObservedObject var notchViewModel: NotchViewModel
    
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content.background(
            NotchSwipeDismissMonitorRepresentable(
                canSwipeUp: isEnabled && notchViewModel.canDismissWithTrackpadSwipe,
                canSwipeDown: isEnabled && notchViewModel.canRestoreWithTrackpadSwipe,
                canSwipeHorizontal: isEnabled && notchViewModel.canDismissWithHorizontalTrackpadSwipe,
                isHoveringScrollableContent: notchViewModel.isHoveringScrollableContent,
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

private struct NotchSwipeDismissMonitorRepresentable: NSViewRepresentable {
    let canSwipeUp: Bool
    let canSwipeDown: Bool
    let canSwipeHorizontal: Bool
    let isHoveringScrollableContent: Bool
    let onSwipeUp: () -> Void
    let onSwipeDown: () -> Void
    let onSwipeHorizontal: () -> Void
    let onSwipeStretchChanged: (SwipeInteraction, CGFloat) -> Void
    let onSwipeStretchReset: () -> Void

    func makeNSView(context: Context) -> NotchSwipeDismissMonitorView {
        let view = NotchSwipeDismissMonitorView()
        view.update(
            canSwipeUp: canSwipeUp,
            canSwipeDown: canSwipeDown,
            canSwipeHorizontal: canSwipeHorizontal,
            isHoveringScrollableContent: isHoveringScrollableContent,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown,
            onSwipeHorizontal: onSwipeHorizontal,
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
            isHoveringScrollableContent: isHoveringScrollableContent,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown,
            onSwipeHorizontal: onSwipeHorizontal,
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

    private enum SwipeDirectionLock {
        case undetermined
        case vertical
        case horizontal
    }

    private var localScrollMonitor: Any?
    private var globalScrollMonitor: Any?

    private var canSwipeUp = false
    private var canSwipeDown = false
    private var canSwipeHorizontal = false
    private var isHoveringScrollableContent = false
    private var onSwipeUp: (() -> Void)?
    private var onSwipeDown: (() -> Void)?
    private var onSwipeHorizontal: (() -> Void)?
    private var onSwipeStretchChanged: ((SwipeInteraction, CGFloat) -> Void)?
    private var onSwipeStretchReset: (() -> Void)?

    private var isTrackingSwipe = false
    private var isGestureActionLocked = false
    private var swipeDirectionLock: SwipeDirectionLock = .undetermined
    private var accumulatedUpwardSwipe: CGFloat = 0
    private var accumulatedDownwardSwipe: CGFloat = 0
    private var accumulatedLeftSwipe: CGFloat = 0
    private var accumulatedRightSwipe: CGFloat = 0
    private var accumulatedHorizontalSwipe: CGFloat = 0
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
        isHoveringScrollableContent: Bool,
        onSwipeUp: @escaping () -> Void,
        onSwipeDown: @escaping () -> Void,
        onSwipeHorizontal: @escaping () -> Void,
        onSwipeStretchChanged: @escaping (SwipeInteraction, CGFloat) -> Void,
        onSwipeStretchReset: @escaping () -> Void
    ) {
        self.canSwipeUp = canSwipeUp
        self.canSwipeDown = canSwipeDown
        self.canSwipeHorizontal = canSwipeHorizontal
        self.isHoveringScrollableContent = isHoveringScrollableContent
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
        self.onSwipeHorizontal = onSwipeHorizontal
        self.onSwipeStretchChanged = onSwipeStretchChanged
        self.onSwipeStretchReset = onSwipeStretchReset

        if !canSwipeUp && !canSwipeDown && !canSwipeHorizontal {
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
        let screenLocation: NSPoint
        if let window = event.window {
            screenLocation = window.convertToScreen(
                NSRect(origin: event.locationInWindow, size: .zero)
            ).origin
        } else {
            screenLocation = NSEvent.mouseLocation
        }

        processScrollEvent(event, screenLocation: screenLocation)
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

        let isInsideNotch = currentScreenRect()?.contains(screenLocation) == true

        if event.phase.contains(.mayBegin) || event.phase.contains(.began) {
            resetSwipeTracking()
            isGestureActionLocked = false
            swipeDirectionLock = .undetermined
            isTrackingSwipe = isInsideNotch
        } else if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
            resetSwipeTracking()
            isGestureActionLocked = false
            return
        } else if isGestureActionLocked {
            return
        } else if !isTrackingSwipe && isInsideNotch {
            isTrackingSwipe = true
        }

        guard isTrackingSwipe else {
            return
        }

        let horizontalDelta = physicalHorizontalDelta(from: event)
        if horizontalDelta > 0 {
            accumulatedRightSwipe += horizontalDelta
            accumulatedLeftSwipe = max(0, accumulatedLeftSwipe - horizontalDelta)
        } else {
            accumulatedLeftSwipe += abs(horizontalDelta)
            accumulatedRightSwipe = max(0, accumulatedRightSwipe + horizontalDelta)
        }
        accumulatedHorizontalSwipe = max(accumulatedLeftSwipe, accumulatedRightSwipe)

        let verticalDelta = physicalVerticalDelta(from: event)
        if verticalDelta > 0 {
            accumulatedUpwardSwipe += verticalDelta
            accumulatedDownwardSwipe = max(0, accumulatedDownwardSwipe - verticalDelta)
        } else {
            accumulatedDownwardSwipe += abs(verticalDelta)
            accumulatedUpwardSwipe = max(0, accumulatedUpwardSwipe + verticalDelta)
        }
        
        let maxVertical = max(accumulatedUpwardSwipe, accumulatedDownwardSwipe)
        if swipeDirectionLock == .undetermined {
            if accumulatedHorizontalSwipe > SwipeMetrics.lockThreshold || maxVertical > SwipeMetrics.lockThreshold {
                if accumulatedHorizontalSwipe > maxVertical * SwipeMetrics.directionDominanceMultiplier {
                    swipeDirectionLock = .horizontal
                } else {
                    swipeDirectionLock = .vertical
                }
            }
        }
        
        if swipeDirectionLock == .horizontal {
            guard canSwipeHorizontal else {
                onSwipeStretchReset?()
                return
            }

            let dominanceThreshold = maxVertical * SwipeMetrics.directionDominanceMultiplier
            let effectiveSwipe = max(0, accumulatedHorizontalSwipe - SwipeMetrics.lockThreshold)
            let effectiveThreshold = max(1, SwipeMetrics.horizontalThreshold - SwipeMetrics.lockThreshold)
            let horizontalProgress = effectiveSwipe / effectiveThreshold

            if horizontalProgress > 0 {
                onSwipeStretchChanged?(.horizontalDismiss, horizontalProgress)
            } else {
                onSwipeStretchReset?()
            }

            if !didTriggerSwipe {
                if accumulatedHorizontalSwipe > dominanceThreshold,
                   accumulatedHorizontalSwipe >= SwipeMetrics.horizontalThreshold {
                    didTriggerSwipe = true
                    isGestureActionLocked = true
                    DispatchQueue.main.async { [weak self] in
                        self?.onSwipeHorizontal?()
                    }
                    resetSwipeTracking()
                    return
                }
            }
            return
        }

        guard swipeDirectionLock != .horizontal else {
            onSwipeStretchReset?()
            return
        }

        let dominanceThreshold =
            accumulatedHorizontalSwipe * SwipeMetrics.directionDominanceMultiplier

        let effectiveUpward = max(0, accumulatedUpwardSwipe - SwipeMetrics.lockThreshold)
        let effectiveDownward = max(0, accumulatedDownwardSwipe - SwipeMetrics.lockThreshold)
        let effectiveVerticalThreshold = max(1, SwipeMetrics.verticalThreshold - SwipeMetrics.lockThreshold)

        let upwardProgress = canSwipeUp
            ? effectiveUpward / effectiveVerticalThreshold
            : 0
        let downwardProgress = canSwipeDown
            ? effectiveDownward / effectiveVerticalThreshold
            : 0

        if upwardProgress > 0 || downwardProgress > 0 {
            if upwardProgress >= downwardProgress {
                onSwipeStretchChanged?(.dismiss, upwardProgress)
            } else {
                onSwipeStretchChanged?(.restore, downwardProgress)
            }
        } else {
            onSwipeStretchReset?()
        }

        if !didTriggerSwipe {
            if canSwipeUp,
               accumulatedUpwardSwipe > dominanceThreshold,
               accumulatedUpwardSwipe >= SwipeMetrics.verticalThreshold {
                didTriggerSwipe = true
                isGestureActionLocked = true
                DispatchQueue.main.async { [weak self] in
                    self?.onSwipeUp?()
                }
                resetSwipeTracking()
                return
            }

            if canSwipeDown,
               accumulatedDownwardSwipe > dominanceThreshold,
               accumulatedDownwardSwipe >= SwipeMetrics.verticalThreshold {
                didTriggerSwipe = true
                isGestureActionLocked = true
                DispatchQueue.main.async { [weak self] in
                    self?.onSwipeDown?()
                }
                resetSwipeTracking()
                return
            }

        }
    }

    func shouldTrackSwipe(for event: NSEvent) -> Bool {
        guard !isHoveringScrollableContent else { return false }
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
        return window.convertToScreen(rectInWindow)
    }

    func physicalVerticalDelta(from event: NSEvent) -> CGFloat {
        let deltaY = CGFloat(event.scrollingDeltaY)
        return event.isDirectionInvertedFromDevice ? -deltaY : deltaY
    }

    func physicalHorizontalDelta(from event: NSEvent) -> CGFloat {
        let deltaX = CGFloat(event.scrollingDeltaX)
        return event.isDirectionInvertedFromDevice ? -deltaX : deltaX
    }

    func resetSwipeTracking() {
        isTrackingSwipe = false
        accumulatedUpwardSwipe = 0
        accumulatedDownwardSwipe = 0
        accumulatedLeftSwipe = 0
        accumulatedRightSwipe = 0
        accumulatedHorizontalSwipe = 0
        didTriggerSwipe = false
        swipeDirectionLock = .undetermined
        onSwipeStretchReset?()
    }
}
