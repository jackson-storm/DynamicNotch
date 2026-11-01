import Foundation

struct HomePageScrollGesture {
    enum Action: Equatable { case passThrough, consume, step(Int) }
    private enum Axis { case undecided, horizontal, vertical }
    private var axis: Axis = .undecided
    private var x: CGFloat = 0
    private var y: CGFloat = 0
    private var didStep = false

    mutating func process(deltaX: CGFloat, deltaY: CGFloat, began: Bool = false, momentum: Bool = false) -> Action {
        guard deltaX.isFinite, deltaY.isFinite else { return .passThrough }
        if momentum { return axis == .vertical ? .consume : .passThrough }
        if began { self = Self() }
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
