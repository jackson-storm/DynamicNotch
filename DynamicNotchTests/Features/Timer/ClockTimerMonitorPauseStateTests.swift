import XCTest
@testable import DynamicNotch

final class ClockTimerMonitorPauseStateTests: XCTestCase {
    private let timerID = "1E8C2F23-9959-4773-901E-1DE4BDD37F18"
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private var domain: CFString!
    private var queue: DispatchQueue!
    private var monitor: ClockTimerMonitor!
    private var snapshots: [ClockTimerSnapshot?] = []

    override func setUp() {
        super.setUp()
        domain = "com.dynamicnotch.tests.clocktimer.\(UUID().uuidString)" as CFString
        queue = DispatchQueue(label: "ClockTimerMonitorPauseStateTests")
        let fixedNow = now
        monitor = ClockTimerMonitor(
            metadataDomain: domain,
            metadataFilePath: "/nonexistent/\(UUID().uuidString).plist",
            dateProvider: { fixedNow },
            queue: queue
        )
        snapshots = []
        monitor.onSnapshotChange = { [weak self] snapshot in
            self?.snapshots.append(snapshot)
        }
    }

    override func tearDown() {
        CFPreferencesSetAppValue("MTTimers" as CFString, nil, domain)
        CFPreferencesAppSynchronize(domain)
        monitor = nil
        queue = nil
        domain = nil
        super.tearDown()
    }

    func testResumeLogLineIsNotOverriddenByDelayedPausedPreferences() {
        writePreferences(running: true)
        monitor.ingestPreferencesChange()
        monitor.ingestLogMessage("<MTTimerScheduler: 0x600001234570> Timer will fire 15.0 minutes from now")
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, false)

        monitor.ingestLogMessage(transitionMessage(from: "Running", to: "Paused"))
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, true)

        writePreferences(running: false)
        monitor.ingestPreferencesChange()
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, true)

        monitor.ingestLogMessage(transitionMessage(from: "Paused", to: "Running"))
        monitor.ingestLogMessage("<MTTimerScheduler: 0x600001234570> Timer will fire 14.6 minutes from now")
        monitor.ingestLogMessage("remainingTime: 876.1")
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
    }

    func testStalePausedPreferencesAfterLoggedResumeKeepTimerRunning() {
        writePreferences(running: true)
        monitor.ingestPreferencesChange()
        monitor.ingestLogMessage("<MTTimerScheduler: 0x600001234570> Timer will fire 15.0 minutes from now")
        monitor.ingestLogMessage(transitionMessage(from: "Running", to: "Paused"))
        monitor.ingestLogMessage(transitionMessage(from: "Paused", to: "Running"))
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, false)

        writePreferences(running: false)
        monitor.ingestPreferencesChange()
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
    }

    func testPreferencesResumeRepublishesWhenNoLogTransitionWasSeen() {
        writePreferences(running: false)
        monitor.ingestPreferencesChange()
        monitor.ingestLogMessage("remainingTime: 600.0")
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, true)

        writePreferences(running: true)
        monitor.ingestPreferencesChange()
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
    }

    func testTrailingRemainingTimeSampleAfterLoggedPauseKeepsTimerPaused() {
        startTimerAndLogPauseAt867()
        let pauseIndex = snapshots.count

        monitor.ingestLogMessage("remainingTime: 866.374438")
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, true)
        XCTAssertEqual(latestSnapshot()?.pausedRemaining, 867)
        let laterRunning = snapshots[pauseIndex...].compactMap { $0 }.filter { !$0.isPaused }
        XCTAssertTrue(laterRunning.isEmpty)
    }

    func testDecreasingSamplesAfterLoggedPauseRecoverAMissedResume() {
        startTimerAndLogPauseAt867()

        monitor.ingestLogMessage("remainingTime: 866.0")
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, true)

        monitor.ingestLogMessage("remainingTime: 863.0")
        monitor.ingestLogMessage("remainingTime: 860.0")
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
    }

    func testMissedResumeRecoveryIgnoresCachedPausedPreferences() {
        startTimerAndLogPauseAt867()
        writePreferences(running: false)
        monitor.ingestPreferencesChange()
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, true)

        monitor.ingestLogMessage("remainingTime: 866.0")
        monitor.ingestLogMessage("remainingTime: 863.0")
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        let firstRunningIndex = snapshots.count - 1

        monitor.ingestLogMessage("remainingTime: 860.0")
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        let laterPaused = snapshots[firstRunningIndex...].compactMap { $0 }.filter { $0.isPaused }
        XCTAssertTrue(laterPaused.isEmpty)
    }

    func testResumeKeepsPausedRemainingDespiteEarlyWillFire() {
        writePreferences(running: true)
        monitor.ingestPreferencesChange()
        monitor.ingestLogMessage("<MTTimerScheduler: 0x600001234570> Timer will fire 14.45 minutes from now")
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, false)

        monitor.ingestLogMessage(transitionMessage(from: "Running", to: "Paused"))
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, true)
        XCTAssertEqual(latestSnapshot()?.pausedRemaining, 867)

        monitor.ingestLogMessage(transitionMessage(from: "Paused", to: "Running"))
        monitor.ingestLogMessage("<MTTimerScheduler: 0x600001234570> Timer will fire 14.09 minutes from now")
        monitor.ingestLogMessage(scheduledTimersMessage(state: "Running"))
        settle()

        let latest = latestSnapshot()
        XCTAssertEqual(latest?.isPaused, false)
        XCTAssertEqual(latest?.remainingTime(at: now) ?? 0, 867, accuracy: 1)
        let dipped = snapshots.compactMap { $0 }.filter { abs($0.remainingTime(at: now) - 845) <= 2 }
        XCTAssertTrue(dipped.isEmpty)
    }

    func testWillFireSeedsRemainingWhenNothingIsKnown() {
        monitor.ingestLogMessage("started timer: \(timerID)")
        monitor.ingestLogMessage("<MTTimerScheduler: 0x600001234570> Timer will fire 14.83 minutes from now")
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        XCTAssertEqual(latestSnapshot()?.remainingTime(at: now) ?? 0, 890, accuracy: 1)
    }

    func testPreferencesFireDateCorrectsEarlyWillFire() {
        writePreferences(running: true)
        monitor.ingestPreferencesChange()
        monitor.ingestLogMessage("<MTTimerScheduler: 0x600001234570> Timer will fire 14.83 minutes from now")
        settle()
        XCTAssertEqual(latestSnapshot()?.remainingTime(at: now) ?? 0, 890, accuracy: 1)

        writePreferences(running: true, fireDate: now.addingTimeInterval(900))
        monitor.ingestPreferencesChange()
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        XCTAssertEqual(latestSnapshot()?.remainingTime(at: now) ?? 0, 900, accuracy: 1)

        let countAfterCorrection = snapshots.count
        writePreferences(running: true, fireDate: now.addingTimeInterval(900.4))
        monitor.ingestPreferencesChange()
        settle()
        XCTAssertEqual(snapshots.count, countAfterCorrection)
    }

    func testPausedPreferencesIgnoreStaleFireDate() {
        startTimerAndLogPauseAt867()

        writePreferences(running: false, fireDate: now.addingTimeInterval(500))
        monitor.ingestPreferencesChange()
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, true)
        XCTAssertEqual(latestSnapshot()?.pausedRemaining, 867)
    }

    func testFireDateParserAcceptsDateAndDefaultsString() {
        let date = Date(timeIntervalSince1970: 1_793_566_387)
        XCTAssertEqual(ClockTimerPreferencesParser.fireDate(forTimer: fireTime(date)), date)
        XCTAssertEqual(
            ClockTimerPreferencesParser.fireDate(forTimer: fireTime("2026-11-01 20:53:07 +0000")),
            date
        )
        XCTAssertNil(ClockTimerPreferencesParser.fireDate(forTimer: fireTime("not a date")))
        XCTAssertNil(ClockTimerPreferencesParser.fireDate(forTimer: [:]))
    }

    /// Replays the Clock log up to a logged pause. With the fixed date the live remaining time at
    /// the pause rounds to 867, while Clock's trailing sample rounds to 866.
    private func startTimerAndLogPauseAt867() {
        writePreferences(running: true)
        monitor.ingestPreferencesChange()
        monitor.ingestLogMessage("<MTTimerScheduler: 0x600001234570> Timer will fire 14.631088 minutes from now")
        monitor.ingestLogMessage("remainingTime: 888.4")
        monitor.ingestLogMessage("remainingTime: 866.590850")
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, false)

        monitor.ingestLogMessage(transitionMessage(from: "Running", to: "Paused"))
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, true)
        XCTAssertEqual(latestSnapshot()?.pausedRemaining, 867)
    }

    private func latestSnapshot() -> ClockTimerSnapshot? {
        snapshots.last ?? nil
    }

    /// Waits until the monitor's queue is idle and every publish it made has reached the main queue.
    private func settle() {
        queue.sync {}
        let delivered = expectation(description: "main queue drained")
        DispatchQueue.main.async {
            delivered.fulfill()
        }
        wait(for: [delivered], timeout: 2)
    }

    private func writePreferences(running: Bool, fireDate: Date? = nil) {
        var timer: [String: Any] = [
            "MTTimerID": timerID,
            "MTTimerDuration": 900.0,
            "MTTimerState": 2,
            "MTTimerFireTimerClass": running ? "MTTimerDate" : "MTTimerTimeInterval"
        ]
        if let fireDate {
            timer["MTTimerFireTime"] = ["$MTTimerDate": ["MTTimerTimeDate": fireDate]]
        }
        let container: [String: Any] = ["MTTimers": [["$MTTimer": timer]]]
        CFPreferencesSetAppValue("MTTimers" as CFString, container as CFDictionary, domain)
        CFPreferencesAppSynchronize(domain)
    }

    private func fireTime(_ value: Any) -> [String: Any] {
        ["MTTimerFireTime": ["$MTTimerDate": ["MTTimerTimeDate": value]]]
    }

    private func scheduledTimersMessage(state: String) -> String {
        """
        <MTTimerScheduler: 0x600001234570> scheduled timers: (
            "<MTTimer:0x600002345620 TimerID: \(timerID), Title: (null), state:\(state), duration:900, firedDate: (null), dismissedDate: (null), sound: <MTSound:0x1>>"
        )
        """
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
