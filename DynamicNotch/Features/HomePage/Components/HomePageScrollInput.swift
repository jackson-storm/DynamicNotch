internal import AppKit
import SwiftUI

/// Pages have different heights. Observe the gesture without scrolling their
/// contents, so resizing cannot move the selected page or crop its controls.
struct HomePageScrollInput: NSViewRepresentable {
    let onStep: (Int, CGSize) -> Void

    func makeNSView(context: Context) -> HomePageScrollMonitorView {
        let view = HomePageScrollMonitorView()
        view.onStep = onStep
        return view
    }

    func updateNSView(_ view: HomePageScrollMonitorView, context: Context) { view.onStep = onStep }

    static func dismantleNSView(_ view: HomePageScrollMonitorView, coordinator: ()) { view.stopMonitoring() }
}

final class HomePageScrollMonitorView: NSView {
    var onStep: ((Int, CGSize) -> Void)?
    private var monitor: Any?
    private var gesture = HomePageScrollGesture()

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

    deinit { stopMonitoring() }

    func stopMonitoring() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        gesture = HomePageScrollGesture()
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard let window, event.window === window, window.isVisible,
              !isHiddenOrHasHiddenAncestor, !visibleRect.isEmpty else { return event }
        let point = convert(event.locationInWindow, from: nil)
        if (event.phase.contains(.began) || event.phase.contains(.mayBegin)), !visibleRect.contains(point) {
            gesture = HomePageScrollGesture()
            return event
        }
        guard visibleRect.contains(point) || gesture.ownsGesture else { return event }
        switch gesture.process(event) {
        case .passThrough: return event
        case .consume: return nil
        case .step(let direction):
            let pointer = CGPoint(x: point.x - bounds.minX, y: bounds.maxY - point.y)
            onStep?(direction, HomePageNavigationLayout.minimumSize(size: bounds.size, pointer: pointer))
            return nil
        }
    }
}

extension HomePageScrollGesture {
    mutating func process(_ event: NSEvent) -> Action {
        let phase: Phase
        if event.phase.contains(.cancelled) { phase = .cancelled }
        else if event.phase.contains(.ended) { phase = .ended }
        else if event.phase.contains(.began) { phase = .began }
        else if event.phase.contains(.mayBegin) { phase = .mayBegin }
        else if event.phase.isEmpty { phase = .none }
        else { phase = .changed }
        return process(deltaX: event.scrollingDeltaX, deltaY: event.scrollingDeltaY,
                       phase: phase, momentum: !event.momentumPhase.isEmpty,
                       precise: event.hasPreciseScrollingDeltas, timestamp: event.timestamp)
    }
}
