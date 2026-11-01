internal import AppKit
import SwiftUI

/// Keeps the ruler's horizontal scrolling separate from vertical home-page scrolling.
struct TimerRulerScrollGesture {
    enum Action: Equatable {
        case passThrough
        case consume
        case changed(CGFloat)
        case ended
    }

    private enum Axis {
        case undecided, horizontal, vertical
    }

    private var axis: Axis = .undecided
    private var accumulatedX: CGFloat = 0
    private var accumulatedY: CGFloat = 0

    var isHorizontal: Bool { axis == .horizontal }

    mutating func reset() {
        self = Self()
    }

    mutating func process(
        deltaX: CGFloat,
        deltaY: CGFloat,
        phase: NSEvent.Phase,
        momentumPhase: NSEvent.Phase = []
    ) -> Action {
        // Retain the direction after fingers lift so horizontal momentum cannot
        // alter the timer or start scrolling its enclosing page.
        if !momentumPhase.isEmpty {
            return isHorizontal ? .consume : .passThrough
        }
        guard !phase.isEmpty else { return .passThrough }

        if phase.contains(.began) || phase.contains(.mayBegin) {
            reset()
        }
        if phase.contains(.ended) || phase.contains(.cancelled) {
            return isHorizontal ? .ended : .passThrough
        }

        switch axis {
        case .horizontal:
            return .changed(deltaX)
        case .vertical:
            return .passThrough
        case .undecided:
            accumulatedX += deltaX
            accumulatedY += deltaY
            let horizontal = abs(accumulatedX)
            let vertical = abs(accumulatedY)
            guard max(horizontal, vertical) >= 2 else { return .passThrough }

            if horizontal > vertical * 1.25 {
                axis = .horizontal
                return .changed(accumulatedX)
            }
            if vertical > horizontal * 1.25 {
                axis = .vertical
            }
            return .passThrough
        }
    }
}

/// Bounds the continuous ruler position, including movement between individual ticks.
struct TimerRulerScrollPosition {
    let startIndex: Int
    let maximumIndex: Int
    let tickSpacing: CGFloat
    private(set) var offset: CGFloat = 0

    init(selectedIndex: Int, maximumIndex: Int, tickSpacing: CGFloat) {
        self.startIndex = selectedIndex
        self.maximumIndex = maximumIndex
        self.tickSpacing = tickSpacing
    }

    var selectedIndex: Int {
        let index = Int((CGFloat(startIndex) - offset / tickSpacing).rounded())
        return min(max(1, index), maximumIndex)
    }

    mutating func scroll(by delta: CGFloat) {
        guard delta.isFinite else { return }
        let minimumOffset = CGFloat(startIndex - maximumIndex) * tickSpacing
        let maximumOffset = CGFloat(startIndex - 1) * tickSpacing
        offset = min(max(offset + delta, minimumOffset), maximumOffset)
    }
}

struct TimerRulerScrollInput: NSViewRepresentable {
    let isEnabled: Bool
    let onScroll: (CGFloat) -> Void
    let onEnd: () -> Void

    func makeNSView(context: Context) -> TimerRulerScrollMonitorView {
        let view = TimerRulerScrollMonitorView()
        updateNSView(view, context: context)
        return view
    }

    func updateNSView(_ nsView: TimerRulerScrollMonitorView, context: Context) {
        nsView.isEnabled = isEnabled
        nsView.onScroll = onScroll
        nsView.onEnd = onEnd
    }

    static func dismantleNSView(_ nsView: TimerRulerScrollMonitorView, coordinator: ()) {
        nsView.stopMonitoring()
    }
}

final class TimerRulerScrollMonitorView: NSView {
    var isEnabled = true
    var onScroll: ((CGFloat) -> Void)?
    var onEnd: (() -> Void)?

    private var monitor: Any?
    private var gesture = TimerRulerScrollGesture()

    // Observe scroll events without covering the existing click/drag controls.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self else { return event }
            return self.handle(event)
        }
    }

    deinit {
        stopMonitoring()
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        gesture.reset()
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard isEnabled,
              let window,
              event.window === window,
              window.isVisible,
              !isHiddenOrHasHiddenAncestor,
              !visibleRect.isEmpty,
              event.hasPreciseScrollingDeltas else {
            return event
        }

        let point = convert(event.locationInWindow, from: nil)
        let isInside = visibleRect.contains(point)
        let isBeginning = event.phase.contains(.began) || event.phase.contains(.mayBegin)
        if isBeginning && !isInside {
            gesture.reset()
            return event
        }
        guard isInside || gesture.isHorizontal else { return event }

        switch gesture.process(
            deltaX: event.scrollingDeltaX,
            deltaY: event.scrollingDeltaY,
            phase: event.phase,
            momentumPhase: event.momentumPhase
        ) {
        case .passThrough:
            return event
        case .consume:
            return nil
        case .changed(let delta):
            onScroll?(delta)
            return nil
        case .ended:
            onEnd?()
            return nil
        }
    }
}
