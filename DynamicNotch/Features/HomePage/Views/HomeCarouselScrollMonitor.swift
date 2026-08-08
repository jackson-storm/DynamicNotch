import SwiftUI
internal import AppKit

struct HomeCarouselScrollMonitor: NSViewRepresentable {
    let axis: HomePageScrollAxis
    let isEnabled: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void

    func makeNSView(context: Context) -> HomeCarouselScrollMonitorView {
        let view = HomeCarouselScrollMonitorView()
        view.update(axis: axis, isEnabled: isEnabled, onNext: onNext, onPrevious: onPrevious)
        return view
    }

    func updateNSView(_ nsView: HomeCarouselScrollMonitorView, context: Context) {
        nsView.update(axis: axis, isEnabled: isEnabled, onNext: onNext, onPrevious: onPrevious)
    }

    static func dismantleNSView(_ nsView: HomeCarouselScrollMonitorView, coordinator: ()) {
        nsView.stopMonitoring()
    }
}

final class HomeCarouselScrollMonitorView: NSView {
    private enum Metrics {
        static let triggerThreshold: CGFloat = 36
        static let directionDominance: CGFloat = 1.2
    }

    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var axis: HomePageScrollAxis = .horizontal
    private var isEnabled = false
    private var onNext: (() -> Void)?
    private var onPrevious: (() -> Void)?
    private var isTracking = false
    private var isLocked = false
    private var primaryDistance: CGFloat = 0
    private var crossDistance: CGFloat = 0

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
        axis: HomePageScrollAxis,
        isEnabled: Bool,
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void
    ) {
        self.axis = axis
        self.isEnabled = isEnabled
        self.onNext = onNext
        self.onPrevious = onPrevious

        if !isEnabled {
            resetGesture()
        }
    }

    func stopMonitoring() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        localMonitor = nil
        globalMonitor = nil
        resetGesture()
    }
}

private extension HomeCarouselScrollMonitorView {
    func installMonitorsIfNeeded() {
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.process(event, at: self?.screenLocation(for: event) ?? NSEvent.mouseLocation)
                return event
            }
        }

        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                DispatchQueue.main.async {
                    self?.process(event, at: NSEvent.mouseLocation)
                }
            }
        }
    }

    func process(_ event: NSEvent, at screenLocation: NSPoint) {
        guard isEnabled, window != nil, event.hasPreciseScrollingDeltas else {
            resetGesture()
            return
        }

        if !event.momentumPhase.isEmpty {
            return
        }

        if event.phase.contains(.ended) || event.phase.contains(.cancelled) {
            resetGesture()
            return
        }

        let isInside = currentScreenRect()?.contains(screenLocation) == true
        if event.phase.contains(.mayBegin) || event.phase.contains(.began) {
            resetGesture()
            isTracking = isInside
        } else if !isTracking && isInside {
            isTracking = true
        }

        guard isTracking, !isLocked else { return }

        let horizontal = physicalDelta(event.scrollingDeltaX, event: event)
        let vertical = physicalDelta(event.scrollingDeltaY, event: event)
        let primary = axis == .horizontal ? horizontal : vertical
        let cross = axis == .horizontal ? vertical : horizontal

        primaryDistance += primary
        crossDistance += abs(cross)

        guard abs(primaryDistance) >= Metrics.triggerThreshold,
              abs(primaryDistance) > crossDistance * Metrics.directionDominance else { return }

        isLocked = true
        let action = primaryDistance > 0 ? onNext : onPrevious
        DispatchQueue.main.async {
            action?()
        }
    }

    func screenLocation(for event: NSEvent) -> NSPoint {
        guard let eventWindow = event.window else { return NSEvent.mouseLocation }
        return eventWindow.convertToScreen(NSRect(origin: event.locationInWindow, size: .zero)).origin
    }

    func currentScreenRect() -> CGRect? {
        guard let window else { return nil }
        return window.convertToScreen(convert(bounds, to: nil))
    }

    func physicalDelta(_ delta: CGFloat, event: NSEvent) -> CGFloat {
        event.isDirectionInvertedFromDevice ? -delta : delta
    }

    func resetGesture() {
        isTracking = false
        isLocked = false
        primaryDistance = 0
        crossDistance = 0
    }
}
