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

    private func assertAligned(_ start: Date, endDate: Date, remaining: TimeInterval, line: UInt = #line) {
        XCTAssertLessThanOrEqual(start, now, "remaining \(remaining)", line: line)
        XCTAssertGreaterThan(start, now.addingTimeInterval(-1), "remaining \(remaining)", line: line)

        let offset = endDate.timeIntervalSince(start)
        XCTAssertEqual(offset, offset.rounded(), accuracy: 0.000_01, "remaining \(remaining)", line: line)
    }
}
