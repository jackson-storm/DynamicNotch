import XCTest
import SwiftUI
@testable import DynamicNotch

final class TimerCompactIndicatorViewTests: XCTestCase {
    func testRunningTimerShowsASmallGapFromTheStart() {
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 0, remaining: 900, isPaused: false), 0.92, accuracy: 0.000_001)
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 0.05, remaining: 855, isPaused: false), 0.92, accuracy: 0.000_001)
    }

    func testRingEmptiesAsTheTimerRuns() {
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 0.25, remaining: 675, isPaused: false), 0.75, accuracy: 0.000_001)
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 0.9, remaining: 90, isPaused: false), 0.1, accuracy: 0.000_001)
    }

    func testRunningTimerKeepsASmallArcUntilItEnds() {
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 0.999, remaining: 0.9, isPaused: false), 0.03, accuracy: 0.000_001)
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 1, remaining: 0, isPaused: false), 0, accuracy: 0.000_001)
    }

    func testPausedTimerShowsTheExactRemainingShare() {
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 0.999, remaining: 0.9, isPaused: true), 0.001, accuracy: 0.000_001)
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 0.4, remaining: 540, isPaused: true), 0.6, accuracy: 0.000_001)
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 0, remaining: 900, isPaused: true), 1, accuracy: 0.000_001)
    }

    func testOutOfRangeElapsedFractionIsClamped() {
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: -0.5, remaining: 900, isPaused: false), 0.92, accuracy: 0.000_001)
        XCTAssertEqual(TimerCompactIndicatorView.ringFraction(elapsedFraction: 1.5, remaining: 1, isPaused: true), 0, accuracy: 0.000_001)
    }

    func testHandSweepsCounterclockwiseFromTheTop() {
        XCTAssertEqual(TimerCompactIndicatorView.handAngle(remainingFraction: 1).degrees, -90, accuracy: 0.000_001)
        XCTAssertEqual(TimerCompactIndicatorView.handAngle(remainingFraction: 0.75).degrees, -180, accuracy: 0.000_001)
        XCTAssertEqual(TimerCompactIndicatorView.handAngle(remainingFraction: 0.5).degrees, -270, accuracy: 0.000_001)
    }
}
