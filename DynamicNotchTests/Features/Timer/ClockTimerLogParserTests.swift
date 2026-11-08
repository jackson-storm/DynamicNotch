import XCTest
@testable import DynamicNotch

final class ClockTimerLogParserTests: XCTestCase {
    private let timerID = "1E8C2F23-9959-4773-901E-1DE4BDD37F18"

    func testPauseTransitionYieldsPausedEntry() {
        let entries = ClockTimerLogParser.updatedTimers(in: transitionMessage(from: "Running", to: "Paused"))

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.identifier, timerID)
        XCTAssertEqual(entries.first?.state, .paused)
        XCTAssertEqual(entries.first?.duration, 900)
    }

    func testResumeTransitionYieldsRunningEntry() {
        let entries = ClockTimerLogParser.updatedTimers(in: transitionMessage(from: "Paused", to: "Running"))

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.identifier, timerID)
        XCTAssertEqual(entries.first?.state, .running)
    }

    func testFromTimersSectionIsIgnored() {
        let message = transitionMessage(from: "Running", to: "Paused")

        XCTAssertEqual(ClockTimerLogParser.timers(in: message).map(\.state), [.running, .paused])
        XCTAssertEqual(ClockTimerLogParser.updatedTimers(in: message).map(\.state), [.paused])
    }

    func testReturningTimersMessageIsNotATransition() {
        let message = """
        <MTTimerStorage: 0x600001234560> returning timers: (
            "<MTMutableTimer:0x600002345670 TimerID: \(timerID), Title: (null), state:Paused, duration:900, firedDate: (null), dismissedDate: (null), sound: <MTSound:0x1>>",
            "<MTMutableTimer:0x600002345680 TimerID: CURRENT_TIMER, state:Stopped, duration:300>"
        ), next timer: <MTTimer:0x600002345690 TimerID: \(timerID), state:Running, duration:900>
        """

        XCTAssertTrue(ClockTimerLogParser.updatedTimers(in: message).isEmpty)
    }

    func testRunningPreferencesTimerWithDateFireTimeMapsToRunning() {
        let timer: [String: Any] = [
            "MTTimerState": 2,
            "MTTimerFireTimerClass": "MTTimerDate"
        ]

        XCTAssertEqual(ClockTimerPreferencesParser.state(forTimer: timer), .running)
    }

    func testRunningPreferencesTimerWithIntervalFireTimeMapsToPaused() {
        let timer: [String: Any] = [
            "MTTimerState": 2,
            "MTTimerFireTimerClass": "MTTimerTimeInterval"
        ]

        XCTAssertEqual(ClockTimerPreferencesParser.state(forTimer: timer), .paused)
    }

    func testClockPersistsThreeForRunningAndTwoForPaused() {
        XCTAssertEqual(ClockTimerPreferencesParser.state(forTimer: ["MTTimerState": 3, "MTTimerFireTimerClass": "MTTimerDate"]), .running)
        XCTAssertEqual(ClockTimerPreferencesParser.state(forTimer: ["MTTimerState": 3]), .running)
        XCTAssertEqual(ClockTimerPreferencesParser.state(forTimer: ["MTTimerState": 2]), .paused)
        XCTAssertEqual(ClockTimerPreferencesParser.state(forTimer: ["MTTimerState": 3, "MTTimerFireTimerClass": "MTTimerTimeInterval"]), .running)
    }

    func testOtherPreferencesStatesKeepRawMapping() {
        XCTAssertEqual(ClockTimerPreferencesParser.state(forTimer: ["MTTimerState": 1]), .stopped)
        XCTAssertEqual(ClockTimerPreferencesParser.state(forTimer: ["MTTimerState": 4]), .fired)
        XCTAssertEqual(ClockTimerPreferencesParser.state(forTimer: ["MTTimerState": 9]), .unknown)
    }

    func testLogTimestampKeepsMicroseconds() throws {
        let pacific = try XCTUnwrap(ClockTimerLogParser.logTimestamp("2026-11-02 11:20:38.639916-0800"))
        XCTAssertEqual(pacific.timeIntervalSince1970, 1_793_647_238.639916, accuracy: 0.000_001)

        let india = try XCTUnwrap(ClockTimerLogParser.logTimestamp("2026-11-02 11:20:38.639916+0530"))
        XCTAssertEqual(india.timeIntervalSince1970, 1_793_598_638.639916, accuracy: 0.000_001)
    }

    func testLogTimestampRejectsMalformedInput() {
        XCTAssertNil(ClockTimerLogParser.logTimestamp("not a date"))
        XCTAssertNil(ClockTimerLogParser.logTimestamp("2026-11-02 11:20:38.-0800"))
        XCTAssertNil(ClockTimerLogParser.logTimestamp("2026-11-02 11:20:38.639916"))
        XCTAssertNil(ClockTimerLogParser.logTimestamp("2026-11-02 11:20:38.639916-08"))
        XCTAssertNil(ClockTimerLogParser.logTimestamp(""))
    }

    private func transitionMessage(from oldState: String, to newState: String) -> String {
        """
        <MTTimerDurationManager: 0x600001234500> didUpdateTimers fromTimers: (
            "<MTMutableTimer:0x600002345600 TimerID: \(timerID), Title: (null), state:\(oldState), duration:900, firedDate: (null), dismissedDate: (null), sound: <MTSound:0x1>>"
        ) toTimers: (
            "<MTMutableTimer:0x600002345610 TimerID: \(timerID), Title: (null), state:\(newState), duration:900, firedDate: (null), dismissedDate: (null), sound: <MTSound:0x1>>"
        )
        """
    }
}
