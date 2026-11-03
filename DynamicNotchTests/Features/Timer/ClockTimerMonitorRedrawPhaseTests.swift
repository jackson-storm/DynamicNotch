import XCTest
@testable import DynamicNotch

final class ClockTimerMonitorRedrawPhaseTests: XCTestCase {
    private let timerID = "1E8C2F23-9959-4773-901E-1DE4BDD37F18"
    /// 2026-11-02 11:20:38.000000-0800, the base of every `timestamp(_:)` string.
    private let base = Date(timeIntervalSince1970: 1_793_647_238)
    /// Clock's samples arrive this long after their own log time.
    private let arrivalLag: TimeInterval = 0.030
    private let endOffset: TimeInterval = 899.8278

    private var domain: CFString!
    private var queue: DispatchQueue!
    private var monitor: ClockTimerMonitor!
    private var snapshots: [ClockTimerSnapshot?] = []
    private var clock: TestClock!

    override func setUp() {
        super.setUp()
        domain = "com.dynamicnotch.tests.clocktimer.phase.\(UUID().uuidString)" as CFString
        queue = DispatchQueue(label: "ClockTimerMonitorRedrawPhaseTests")
        let clock = TestClock(now: base)
        self.clock = clock
        monitor = ClockTimerMonitor(
            metadataDomain: domain,
            metadataFilePath: "/nonexistent/\(UUID().uuidString).plist",
            dateProvider: { clock.now },
            queue: queue
        )
        snapshots = []
        monitor.onSnapshotChange = { [weak self] snapshot in
            self?.snapshots.append(snapshot)
        }

        writeRunningPreferences()
        monitor.ingestPreferencesChange()
        settle()
    }

    override func tearDown() {
        CFPreferencesSetAppValue("MTTimers" as CFString, nil, domain)
        CFPreferencesAppSynchronize(domain)
        monitor = nil
        queue = nil
        domain = nil
        clock = nil
        super.tearDown()
    }

    func testEndDateUsesTheSampleLogTime() {
        clock.now = base.addingTimeInterval(arrivalLag)
        monitor.ingestLogLine(logLine(at: 0, message: "remainingTime: 898.558"))
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        XCTAssertEqual(latestSnapshot()?.endDate.timeIntervalSince(base) ?? 0, 898.558, accuracy: 0.000_001)
    }

    func testUnparsedTimestampFallsBackToArrivalTime() {
        clock.now = base.addingTimeInterval(arrivalLag)
        monitor.ingestLogLine(#"{"timestamp":"garbage","eventMessage":"remainingTime: 898.558"}"#)
        settle()

        XCTAssertEqual(latestSnapshot()?.endDate.timeIntervalSince(base) ?? 0, 898.588, accuracy: 0.000_001)
    }

    func testDelayIsUnknownUntilTheRedrawGridIsSteady() {
        for offset in [0, 0.1338, 0.3443, 0.5943, 0.8443] {
            sample(at: offset)
            XCTAssertEqual(latestSnapshot()?.displayDelay, 0, "offset \(offset)")
        }

        sample(at: 1.0943)
        let learned = expectedDelay(at: 1.0943)
        XCTAssertEqual(learned, 0.0164, accuracy: 0.000_2)
        XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, learned, accuracy: 0.000_001)
        XCTAssertEqual(latestSnapshot()?.endDate.timeIntervalSince(base) ?? 0, endOffset, accuracy: 0.000_001)

        let countAfterLearning = snapshots.count
        sample(at: 1.3443)
        XCTAssertEqual(snapshots.count, countAfterLearning)
    }

    func testStartUpRedrawNearAWrongFrameLengthDoesNotFixTheGrid() {
        // A measured start: the first interval, 163.8 ms, is within 5 ms of 1/6 s.
        let measured: [(TimeInterval, TimeInterval)] = [
            (0, 899.8740), (0.1638, 899.7102), (0.3470, 899.5270), (0.5972, 899.2767),
            (0.8466, 899.0273), (1.0984, 898.7755), (1.3470, 898.5270), (1.5978, 898.2762)
        ]
        for (offset, remaining) in measured {
            sample(at: offset, remaining: remaining)
        }

        XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, 0.2230, accuracy: 0.002)
    }

    func testLateRedrawsKeepTheLearnedDelay() {
        let lastGridOffset = establishPhase()
        let countAfterLearning = snapshots.count

        let late = lastGridOffset + 0.2510
        sample(at: late, remaining: remaining(forDelay: 0.1968, near: endOffset - late))
        let later = late + 0.2521
        sample(at: later, remaining: remaining(forDelay: 0.1989, near: endOffset - later))

        XCTAssertEqual(snapshots.count, countAfterLearning)
        XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, establishedDelay, accuracy: 0.000_001)
    }

    func testDroppedSampleAndGapKeepTheLearnedDelay() {
        let lastGridOffset = establishPhase()
        let countAfterLearning = snapshots.count

        for offset in [lastGridOffset + 0.5, lastGridOffset + 0.75, lastGridOffset + 2.75, lastGridOffset + 3] {
            sample(at: offset)
            XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, establishedDelay, accuracy: 0.000_001, "offset \(offset)")
        }
        XCTAssertEqual(snapshots.count, countAfterLearning)
    }

    func testSingleOffPhaseRedrawIsIgnored() {
        let lastGridOffset = establishPhase()
        let countAfterLearning = snapshots.count

        sample(at: lastGridOffset + 0.25 + (0.080 - establishedDelay))
        XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, establishedDelay, accuracy: 0.000_001)
        sample(at: lastGridOffset + 0.5)
        XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, establishedDelay, accuracy: 0.000_001)
        XCTAssertEqual(snapshots.count, countAfterLearning)
    }

    func testTwoAgreeingOffPhaseRedrawsAdoptTheNewPhase() {
        let lastGridOffset = establishPhase()
        let countAfterLearning = snapshots.count

        let first = lastGridOffset + 0.25 + (0.080 - establishedDelay)
        sample(at: first)
        XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, establishedDelay, accuracy: 0.000_001)
        sample(at: first + 0.2515)

        XCTAssertEqual(snapshots.count, countAfterLearning + 1)
        XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, 0.08075, accuracy: 0.000_001)
    }

    func testPauseResetsDelayAndResumeLearnsAgain() {
        for offset in [0, 0.1338, 0.3443, 0.5943, 0.8443, 1.0943] {
            sample(at: offset)
        }
        XCTAssertGreaterThan(latestSnapshot()?.displayDelay ?? 0, 0.004)

        monitor.ingestLogMessage(transitionMessage(from: "Running", to: "Paused"))
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, true)
        XCTAssertEqual(latestSnapshot()?.displayDelay, 0)

        clock.now = base.addingTimeInterval(10)
        monitor.ingestLogMessage(transitionMessage(from: "Paused", to: "Running"))
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        XCTAssertEqual(latestSnapshot()?.displayDelay, 0)

        let resumedEnd = 10 + endOffset - 0.9
        for offset in [10, 10.1338, 10.3443, 10.5943, 10.8443] {
            sample(at: offset, endOffset: resumedEnd)
            XCTAssertEqual(latestSnapshot()?.displayDelay, 0, "offset \(offset)")
        }

        sample(at: 11.0943, endOffset: resumedEnd)
        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        XCTAssertEqual(
            latestSnapshot()?.displayDelay ?? 0,
            expectedDelay(at: 11.0943, endOffset: resumedEnd),
            accuracy: 0.000_001
        )
    }

    func testDelayNearTheGridPeriodIsPublished() {
        _ = establishPhase(delay: 0.248)
        XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, 0.248, accuracy: 0.000_001)
    }

    func testCircularMedianAcrossTheGridBoundary() {
        let median = ClockTimerMonitor.circularMedian([0.249, 0.001, 0.003], period: 0.25)
        XCTAssertEqual(median, 0.001, accuracy: 0.000_001)
        XCTAssertEqual(ClockTimerMonitor.circularDistance(0.249, 0.001, period: 0.25), 0.002, accuracy: 0.000_001)
    }

    func testGridPeriodNeedsThreeIntervalsWithinFiveMillisecondsOfAFrame() {
        XCTAssertNil(ClockTimerMonitor.redrawGridPeriod(intervals: [0.1638]))
        XCTAssertNil(ClockTimerMonitor.redrawGridPeriod(intervals: [0.1638, 0.1832, 0.2503]))
        XCTAssertNil(ClockTimerMonitor.redrawGridPeriod(intervals: [0.1338, 0.2105, 0.25, 0.25]))
        XCTAssertNil(ClockTimerMonitor.redrawGridPeriod(intervals: [0.25, 0.25, 0.5]))
        XCTAssertNil(ClockTimerMonitor.redrawGridPeriod(intervals: [0.2531, 0.2549]))
        XCTAssertNil(ClockTimerMonitor.redrawGridPeriod(intervals: [0.25, 0.25, 0.2551]))
        XCTAssertEqual(ClockTimerMonitor.redrawGridPeriod(intervals: [0.1338, 0.25, 0.25, 0.25]), 0.25)
        XCTAssertEqual(ClockTimerMonitor.redrawGridPeriod(intervals: [0.2503, 0.2494, 0.2518]), 0.25)
        XCTAssertEqual(ClockTimerMonitor.redrawGridPeriod(intervals: [0.25, 0.2549, 0.2451]), 0.25)
    }

    private let establishedDelay: TimeInterval = 0.1965

    /// Samples four redraws on a 250 ms grid whose implied delay is `establishedDelay`, and
    /// returns the offset of the last one.
    private func establishPhase(delay: TimeInterval? = nil) -> TimeInterval {
        let delay = delay ?? establishedDelay
        let firstOffset = (delay - 0.5 + endOffset).truncatingRemainder(dividingBy: 0.25)
        let offsets = (0..<4).map { firstOffset + Double($0) * 0.25 }
        for offset in offsets {
            sample(at: offset)
        }
        XCTAssertEqual(latestSnapshot()?.displayDelay ?? 0, delay, accuracy: 0.000_001)
        return offsets[3]
    }

    /// The remaining time nearest `approximate` whose implied delay on a 250 ms grid is `delay`.
    private func remaining(forDelay delay: TimeInterval, near approximate: TimeInterval) -> TimeInterval {
        0.5 - delay + 0.25 * ((approximate - 0.5 + delay) / 0.25).rounded()
    }

    private func sample(at offset: TimeInterval, remaining: TimeInterval) {
        clock.now = base.addingTimeInterval(offset + arrivalLag)
        monitor.ingestLogLine(logLine(at: offset, message: "remainingTime: \(remaining)"))
        settle()
    }

    private func sample(at offset: TimeInterval, endOffset: TimeInterval? = nil) {
        let remaining = (endOffset ?? self.endOffset) - offset
        clock.now = base.addingTimeInterval(offset + arrivalLag)
        monitor.ingestLogLine(logLine(at: offset, message: "remainingTime: \(remaining)"))
        settle()
    }

    private func expectedDelay(at offset: TimeInterval, endOffset: TimeInterval? = nil) -> TimeInterval {
        let remaining = (endOffset ?? self.endOffset) - offset
        let delay = (0.5 - remaining).truncatingRemainder(dividingBy: 0.25)
        return delay < 0 ? delay + 0.25 : delay
    }

    /// Builds a `log stream --style ndjson` line logged `offset` seconds after `base`.
    private func logLine(at offset: TimeInterval, message: String) -> String {
        let minutes = 20 + Int((38 + offset) / 60)
        let seconds = (38 + offset).truncatingRemainder(dividingBy: 60)
        let timestamp = String(format: "2026-11-02 11:%02d:%09.6f-0800", minutes, seconds)
        return #"{"timestamp":"\#(timestamp)","eventMessage":"\#(message)"}"#
    }

    private func latestSnapshot() -> ClockTimerSnapshot? {
        snapshots.last ?? nil
    }

    private func settle() {
        queue.sync {}
        let delivered = expectation(description: "main queue drained")
        DispatchQueue.main.async {
            delivered.fulfill()
        }
        wait(for: [delivered], timeout: 2)
    }

    private func writeRunningPreferences() {
        let timer: [String: Any] = [
            "MTTimerID": timerID,
            "MTTimerDuration": 900.0,
            "MTTimerState": 2,
            "MTTimerFireTimerClass": "MTTimerDate"
        ]
        let container: [String: Any] = ["MTTimers": [["$MTTimer": timer]]]
        CFPreferencesSetAppValue("MTTimers" as CFString, container as CFDictionary, domain)
        CFPreferencesAppSynchronize(domain)
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

private final class TestClock: @unchecked Sendable {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}
