internal import AppKit
import SwiftUI

/// Pages have different heights. Observe the gesture without scrolling their
/// contents, so resizing cannot move the selected page or crop its controls.
struct HomePageScrollInput: NSViewRepresentable {
    let onStep: (Int) -> Void

    func makeNSView(context: Context) -> HomePageScrollMonitorView {
        let view = HomePageScrollMonitorView()
        view.onStep = onStep
        return view
    }

    func updateNSView(_ view: HomePageScrollMonitorView, context: Context) { view.onStep = onStep }

    static func dismantleNSView(_ view: HomePageScrollMonitorView, coordinator: ()) { view.stopMonitoring() }
}

final class HomePageScrollMonitorView: NSView {
    var onStep: ((Int) -> Void)?
    private var monitor: Any?
    private var gesture = HomePageScrollGesture()
    private var lastWheelStep: TimeInterval = -.infinity

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
              !isHiddenOrHasHiddenAncestor, !visibleRect.isEmpty,
              visibleRect.contains(convert(event.locationInWindow, from: nil)) else { return event }

        if event.phase.isEmpty && event.momentumPhase.isEmpty {
            guard abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX) * 1.25 else { return event }
            if abs(event.scrollingDeltaY) > 0, event.timestamp - lastWheelStep > 0.3 {
                lastWheelStep = event.timestamp
                onStep?(event.scrollingDeltaY < 0 ? 1 : -1)
            }
            return nil
        }
        switch gesture.process(
            deltaX: event.scrollingDeltaX, deltaY: event.scrollingDeltaY,
            began: event.phase.contains(.began) || event.phase.contains(.mayBegin),
            momentum: !event.momentumPhase.isEmpty
        ) {
        case .passThrough: return event
        case .consume: return nil
        case .step(let direction): onStep?(direction); return nil
        }
    }
}
