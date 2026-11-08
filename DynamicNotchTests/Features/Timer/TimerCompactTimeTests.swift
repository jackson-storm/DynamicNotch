import XCTest
@testable import DynamicNotch

final class TimerCompactTimeTests: XCTestCase {
    func testTenMinutesOrLessKeepsMinutesAndSeconds() {
        XCTAssertNil(TimerSource.abbreviatedTime(0))
        XCTAssertNil(TimerSource.abbreviatedTime(599))
        XCTAssertNil(TimerSource.abbreviatedTime(600))
    }

    func testAboveTenMinutesShowsWholeMinutes() {
        XCTAssertEqual(TimerSource.abbreviatedTime(601), "10m")
        XCTAssertEqual(TimerSource.abbreviatedTime(659), "10m")
        XCTAssertEqual(TimerSource.abbreviatedTime(660), "11m")
        XCTAssertEqual(TimerSource.abbreviatedTime(900), "15m")
        XCTAssertEqual(TimerSource.abbreviatedTime(3599), "59m")
    }

    func testAnHourOrMoreShowsHoursAndMinutes() {
        XCTAssertEqual(TimerSource.abbreviatedTime(3600), "1h 0m")
        XCTAssertEqual(TimerSource.abbreviatedTime(3660), "1h 1m")
        XCTAssertEqual(TimerSource.abbreviatedTime(5 * 3600 + 30 * 60 + 59), "5h 30m")
        XCTAssertEqual(TimerSource.abbreviatedTime(23 * 3600 + 59 * 60 + 59), "23h 59m")
    }

    @MainActor
    func testCompactTextUsesMinutesAboveTenMinutes() throws {
        let timer = LocalTimerViewModel()
        timer.start(hours: 0, minutes: 15, seconds: 0)
        defer { timer.stop() }
        let endDate = try XCTUnwrap(timer.endDate)
        let source = TimerSource.local(timer)

        XCTAssertEqual(source.formattedTime(at: endDate.addingTimeInterval(-900)), "15m")
        XCTAssertEqual(source.formattedTime(at: endDate.addingTimeInterval(-601)), "10m")
        XCTAssertEqual(source.formattedTime(at: endDate.addingTimeInterval(-600)), "10:00")
        XCTAssertEqual(source.formattedTime(at: endDate.addingTimeInterval(-59)), "0:59")
    }

    @MainActor
    func testCompactWidthFitsEachFormat() {
        XCTAssertEqual(compactWidth(hours: 0, minutes: 5), 110)
        XCTAssertEqual(compactWidth(hours: 0, minutes: 15), 110)
        XCTAssertEqual(compactWidth(hours: 2, minutes: 30), 150)
    }

    func testCountdownRollMatchesTheDeploymentTarget() throws {
        let minimum = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "LSMinimumSystemVersion") as? String)
        XCTAssertEqual(
            minimum.compare("15.0", options: .numeric),
            .orderedAscending,
            "SwiftUI reverses numericText(countsDown:) below a macOS 15 deployment target. Pass countsDown: true in TimerExpandedNotchView once the app targets macOS 15 or later."
        )
    }

    @MainActor
    private func compactWidth(hours: Int, minutes: Int) -> CGFloat {
        let timer = LocalTimerViewModel()
        timer.start(hours: hours, minutes: minutes, seconds: 0)
        defer { timer.stop() }
        return TimerNotchContent(source: .local(timer)).minimalTimerSize
    }
}
