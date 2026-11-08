import XCTest
@testable import DynamicNotch

final class TimerCountdownScheduleTests: XCTestCase {
    private let now = Date(timeIntervalSinceReferenceDate: 815_000_000.123_456)

    func testStartIsAlignedToEndDateForRepresentativeRemainingTimes() {
        for remaining in [0.25, 0.999, 1.5, 59.75, 899.4, 3_600.6] {
            let endDate = now.addingTimeInterval(remaining)
            assertAligned(TimerCountdownSchedule.start(endDate: endDate, now: now), endDate: endDate, remaining: remaining)
        }
    }

    func testExactlyAlignedRemainingStartsNow() {
        for remaining in [1.0, 60.0, 900.0] {
            let endDate = now.addingTimeInterval(remaining)
            let start = TimerCountdownSchedule.start(endDate: endDate, now: now)

            assertAligned(start, endDate: endDate, remaining: remaining)
            XCTAssertEqual(start.timeIntervalSince(now), 0, accuracy: 0.000_01)
        }
    }

    func testPastEndDateIsReturnedUnchanged() {
        let endDate = now.addingTimeInterval(-3.5)
        XCTAssertEqual(TimerCountdownSchedule.start(endDate: endDate, now: now), endDate)
    }

    func testDisplayedSecondsRoundsToNearestSecondWithHalfSecondOffset() {
        XCTAssertEqual(TimerCountdownSchedule.displayedSeconds(remaining: 866.374, flipOffset: 0.5), 866)
        XCTAssertEqual(TimerCountdownSchedule.displayedSeconds(remaining: 866.6, flipOffset: 0.5), 867)
        XCTAssertEqual(TimerCountdownSchedule.displayedSeconds(remaining: 866.5, flipOffset: 0.5), 866)
        XCTAssertEqual(TimerCountdownSchedule.displayedSeconds(remaining: 866.5 + 1e-9, flipOffset: 0.5), 866)
        XCTAssertEqual(TimerCountdownSchedule.displayedSeconds(remaining: 0.4, flipOffset: 0.5), 0)
    }

    func testDisplayedSecondsRoundsUpWithZeroOffset() {
        XCTAssertEqual(TimerCountdownSchedule.displayedSeconds(remaining: 866.374, flipOffset: 0), 867)
        XCTAssertEqual(TimerCountdownSchedule.displayedSeconds(remaining: 866.0, flipOffset: 0), 866)
        XCTAssertEqual(TimerCountdownSchedule.displayedSeconds(remaining: 866.0 + 1e-9, flipOffset: 0), 866)
    }

    func testTicksAlignedToHalfSecondFlipsShowConsecutiveSeconds() {
        let endDate = now.addingTimeInterval(898.558)
        let start = TimerCountdownSchedule.start(endDate: endDate.addingTimeInterval(-0.5), now: now)
        let values = (0..<5).map { tick in
            TimerCountdownSchedule.displayedSeconds(
                remaining: endDate.timeIntervalSince(start.addingTimeInterval(TimeInterval(tick))),
                flipOffset: 0.5
            )
        }

        XCTAssertEqual(values, [899, 898, 897, 896, 895])
    }

    func testTicksDelayedToClockRedrawsShowWhatClockShows() {
        let delay = 0.0164
        let endDate = now.addingTimeInterval(898.558)
        let start = TimerCountdownSchedule.start(endDate: endDate.addingTimeInterval(-(0.5 - delay)), now: now)
        let ticks = (0..<5).map { start.addingTimeInterval(TimeInterval($0)) }

        let values = ticks.map { tick in
            TimerCountdownSchedule.displayedSeconds(remaining: endDate.timeIntervalSince(tick), flipOffset: 0.5 - delay)
        }
        XCTAssertEqual(values, [899, 898, 897, 896, 895])

        for tick in ticks {
            for redraw in [tick, tick.addingTimeInterval(-0.25)] {
                let remaining = endDate.timeIntervalSince(redraw)
                XCTAssertEqual(
                    TimerCountdownSchedule.displayedSeconds(remaining: remaining, flipOffset: 0.5 - delay),
                    Int(remaining.rounded()),
                    "remaining \(remaining)"
                )
            }
        }
    }

    private func assertAligned(_ start: Date, endDate: Date, remaining: TimeInterval, line: UInt = #line) {
        XCTAssertLessThanOrEqual(start, now, "remaining \(remaining)", line: line)
        XCTAssertGreaterThan(start, now.addingTimeInterval(-1), "remaining \(remaining)", line: line)

        let offset = endDate.timeIntervalSince(start)
        XCTAssertEqual(offset, offset.rounded(), accuracy: 0.000_01, "remaining \(remaining)", line: line)
    }
}
