import AppKit
import XCTest
@testable import DynamicNotch

@MainActor
final class TimerRulerScrollGestureTests: XCTestCase {
    func testHorizontalScrollIncludesInitialMovementAndCanReverse() {
        var gesture = TimerRulerScrollGesture()

        XCTAssertEqual(gesture.process(deltaX: 1, deltaY: 0, phase: .began), .passThrough)
        XCTAssertEqual(gesture.process(deltaX: 3, deltaY: 0.5, phase: .changed), .changed(4))
        XCTAssertEqual(gesture.process(deltaX: -9, deltaY: 1, phase: .changed), .changed(-9))
    }

    func testVerticalGestureStaysWithPageScrolling() {
        var gesture = TimerRulerScrollGesture()

        XCTAssertEqual(gesture.process(deltaX: 1, deltaY: 8, phase: .began), .passThrough)
        XCTAssertEqual(gesture.process(deltaX: 20, deltaY: 1, phase: .changed), .passThrough)
        XCTAssertEqual(gesture.process(deltaX: 0, deltaY: 0, phase: .ended), .passThrough)
    }

    func testDiagonalMovementWaitsForAClearDirection() {
        var gesture = TimerRulerScrollGesture()

        XCTAssertEqual(gesture.process(deltaX: 4, deltaY: 4, phase: .began), .passThrough)
        XCTAssertEqual(gesture.process(deltaX: 5, deltaY: 0, phase: .changed), .changed(9))
    }

    func testMomentumDoesNotChangeTimeOrReachPageScroller() {
        var gesture = TimerRulerScrollGesture()

        XCTAssertEqual(gesture.process(deltaX: 9, deltaY: 0, phase: .began), .changed(9))
        XCTAssertEqual(gesture.process(deltaX: 0, deltaY: 0, phase: .ended), .ended)
        XCTAssertEqual(gesture.process(deltaX: 45, deltaY: 1, phase: [], momentumPhase: .began), .consume)
        XCTAssertEqual(gesture.process(deltaX: 9, deltaY: 0, phase: [], momentumPhase: .changed), .consume)
    }

    func testNextGestureResetsThePreviousDirectionAndTranslation() {
        var gesture = TimerRulerScrollGesture()

        _ = gesture.process(deltaX: 18, deltaY: 0, phase: .began)
        _ = gesture.process(deltaX: 0, deltaY: 0, phase: .ended)
        XCTAssertEqual(gesture.process(deltaX: 0, deltaY: 9, phase: .began), .passThrough)
        XCTAssertEqual(gesture.process(deltaX: -9, deltaY: 0, phase: .began), .changed(-9))
    }

    func testCancelledHorizontalGestureFinishesSelection() {
        var gesture = TimerRulerScrollGesture()

        _ = gesture.process(deltaX: 9, deltaY: 0, phase: .began)
        XCTAssertEqual(gesture.process(deltaX: 0, deltaY: 0, phase: .cancelled), .ended)
    }

    func testMouseWheelAndUnrelatedMomentumPassThrough() {
        var gesture = TimerRulerScrollGesture()

        XCTAssertEqual(gesture.process(deltaX: 30, deltaY: 0, phase: []), .passThrough)
        XCTAssertEqual(gesture.process(deltaX: 30, deltaY: 0, phase: [], momentumPhase: .changed), .passThrough)
    }

    func testScrollPositionAccumulatesFineMovement() {
        var position = TimerRulerScrollPosition(selectedIndex: 20, maximumIndex: 125, tickSpacing: 9)

        position.scroll(by: 2)
        XCTAssertEqual(position.selectedIndex, 20)
        position.scroll(by: 3)
        XCTAssertEqual(position.selectedIndex, 19)
        position.scroll(by: -14)
        XCTAssertEqual(position.selectedIndex, 21)
    }

    func testMinimumClampsAndAllowsImmediateReversal() {
        var position = TimerRulerScrollPosition(selectedIndex: 2, maximumIndex: 125, tickSpacing: 9)

        position.scroll(by: 900)
        XCTAssertEqual(position.selectedIndex, 1)
        XCTAssertEqual(position.offset, 9)
        position.scroll(by: -9)
        XCTAssertEqual(position.selectedIndex, 2)
    }

    func testMaximumClampsAndAllowsImmediateReversal() {
        var position = TimerRulerScrollPosition(selectedIndex: 124, maximumIndex: 125, tickSpacing: 9)

        position.scroll(by: -900)
        XCTAssertEqual(position.selectedIndex, 125)
        XCTAssertEqual(position.offset, -9)
        position.scroll(by: 9)
        XCTAssertEqual(position.selectedIndex, 124)
    }
}
