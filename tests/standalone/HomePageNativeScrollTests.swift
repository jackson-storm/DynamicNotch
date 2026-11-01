internal import AppKit
import CoreGraphics

/// These events are unit-test inputs only; none are posted to macOS.
@main
struct HomePageNativeScrollTests {
    @MainActor
    static func main() {
        NSApplication.shared.setActivationPolicy(.prohibited)
        var checked = 0
        func expect(_ value: Bool, _ message: String) {
            guard value else { print("FAIL: \(message)"); exit(1) }
            checked += 1
        }
        func event(_ phase: CGScrollPhase?, x: Int32 = 0, y: Int32, precise: Bool = true, momentum: Int64 = 0) -> NSEvent {
            let cg = CGEvent(scrollWheelEvent2Source: nil, units: precise ? .pixel : .line, wheelCount: 2, wheel1: y, wheel2: x, wheel3: 0)!
            cg.setIntegerValueField(.scrollWheelEventScrollPhase, value: Int64(phase?.rawValue ?? 0))
            cg.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentum)
            cg.setIntegerValueField(.scrollWheelEventIsContinuous, value: precise ? 1 : 0)
            return NSEvent(cgEvent: cg)!
        }
        let begin = event(.began, y: -10)
        expect(begin.phase == .began && begin.hasPreciseScrollingDeltas, "native fixture exposes a precise begin")
        var gesture = HomePageScrollGesture()
        expect(gesture.process(begin) == .consume, "native begin accumulates without selecting early")
        expect(gesture.process(event(.changed, y: -35)) == .step(1), "native changed event selects one next page")
        expect(gesture.process(event(.changed, y: -200)) == .consume, "native continuation cannot skip another page")
        expect(gesture.process(event(.ended, y: -200)) == .consume, "native ended event cannot turn another page")
        expect(gesture.process(event(nil, y: -200, momentum: 1)) == .consume, "native momentum cannot turn another page")
        expect(gesture.process(event(nil, y: -200)) == .consume, "native phase-less precise tail cannot become a wheel step")
        var replacement = HomePageScrollGesture()
        expect(replacement.process(event(.changed, y: -200)) == .passThrough, "newly mounted input ignores an existing gesture")
        expect(replacement.process(event(.mayBegin, y: -200)) == .passThrough, "native may-begin cannot turn a page")
        expect(replacement.process(event(.began, y: 40)) == .step(-1), "new native gesture can reverse direction")
        var cancelled = HomePageScrollGesture()
        _ = cancelled.process(event(.began, y: -5))
        expect(cancelled.process(event(.cancelled, y: -200)) == .consume, "native cancellation cannot turn a page")
        var horizontal = HomePageScrollGesture()
        expect(horizontal.process(event(.began, x: 60, y: 1)) == .passThrough, "native horizontal timer gesture passes through")
        var wheel = HomePageScrollGesture()
        expect(wheel.process(event(nil, y: -1, precise: false)) == .step(1), "native mouse wheel remains supported")
        print("PASS: \(checked) native AppKit scroll checks")
    }
}
