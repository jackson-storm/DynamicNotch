import Foundation

struct HomePageScrollGesture {
    enum Action: Equatable { case passThrough, consume, step(Int) }
    enum Phase { case none, mayBegin, began, changed, ended, cancelled }
    private enum Axis { case undecided, horizontal, vertical }
    private var axis: Axis = .undecided
    private var x: CGFloat = 0
    private var y: CGFloat = 0
    private var didStep = false
    private var isTracking = false
    private var ownsMomentum = false
    private var lastWheelStep: TimeInterval = -.infinity

    var ownsGesture: Bool { isTracking || ownsMomentum }

    mutating func process(deltaX: CGFloat, deltaY: CGFloat, phase: Phase, momentum: Bool = false, precise: Bool = true, timestamp: TimeInterval = 0) -> Action {
        guard deltaX.isFinite, deltaY.isFinite else { return .passThrough }
        if momentum { return ownsMomentum || axis == .vertical ? .consume : .passThrough }
        if phase == .none {
            // Trackpads can send phase-less tail events. They are not mouse
            // wheel detents and must never start another page change.
            guard !precise else { return ownsMomentum || axis == .vertical ? .consume : .passThrough }
            guard abs(deltaY) > abs(deltaX) * 1.25 else { return .passThrough }
            guard deltaY != 0, timestamp - lastWheelStep > 0.3 else { return .consume }
            lastWheelStep = timestamp
            return .step(deltaY < 0 ? 1 : -1)
        }
        if phase == .mayBegin { return .passThrough }
        if phase == .began {
            axis = .undecided; x = 0; y = 0; didStep = false
            isTracking = true; ownsMomentum = false
        }
        if phase == .ended || phase == .cancelled {
            ownsMomentum = axis == .vertical
            isTracking = false
            return ownsMomentum ? .consume : .passThrough
        }
        // A newly mounted view can receive the remainder of an existing
        // gesture. Wait for a real begin instead of interpreting it twice.
        guard isTracking else { return .passThrough }
        x += deltaX; y += deltaY
        if axis == .undecided, max(abs(x), abs(y)) >= 3 {
            if abs(x) > abs(y) * 1.25 { axis = .horizontal }
            else if abs(y) > abs(x) * 1.25 { axis = .vertical }
        }
        guard axis == .vertical else { return .passThrough }
        guard !didStep, abs(y) >= 35 else { return .consume }
        didStep = true
        return .step(y < 0 ? 1 : -1)
    }
}
