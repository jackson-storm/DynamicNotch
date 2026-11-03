import XCTest
@testable import DynamicNotch

/// A new timer starts while the preferences file still describes an older one.
final class ClockTimerMonitorNewTimerTests: XCTestCase {
    private let oldTimerID = "BA9AB7EF-D246-4A86-B16F-3382D08ACA90"
    private let newTimerID = "0AF0C2D1-1111-4A86-B16F-3382D08ACA90"
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private var domain: CFString!
    private var queue: DispatchQueue!
    private var monitor: ClockTimerMonitor!
    private var snapshots: [ClockTimerSnapshot?] = []

    override func setUp() {
        super.setUp()
        domain = "com.dynamicnotch.tests.clocktimer.newtimer.\(UUID().uuidString)" as CFString
        queue = DispatchQueue(label: "ClockTimerMonitorNewTimerTests")
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

    func testNewShorterTimerUsesItsOwnDurationNotTheOlderTimers() {
        writePreferences([(oldTimerID, 1, 900, "MTTimerTimeInterval")])
        monitor.ingestPreferencesChange()

        startNewTimer(duration: 600, willFireMinutes: 9.833273)
        settle()

        XCTAssertEqual(latestSnapshot()?.duration, 600)
        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        XCTAssertEqual(latestSnapshot()?.progress(at: now) ?? 1, 0.0167, accuracy: 0.001)
    }

    func testStartedTimerIsRunningEvenIfStalePreferencesLookPaused() {
        writePreferences([(newTimerID, 2, 60, "MTTimerTimeInterval")])
        monitor.ingestPreferencesChange()

        startNewTimer(duration: 60, willFireMinutes: nil)
        monitor.ingestLogMessage("remainingTime: 59.5")
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        XCTAssertEqual(latestSnapshot()?.duration, 60)
    }

    func testRunningPreferencesStateThreeIsNotReadAsPaused() {
        writePreferences([(newTimerID, 3, 600, "MTTimerDate")])
        monitor.ingestPreferencesChange()
        monitor.ingestLogMessage("remainingTime: 540.0")
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        XCTAssertEqual(latestSnapshot()?.duration, 600)
    }

    func testPreferencesOfAnotherTimerDoNotPauseTheTrackedOne() {
        startNewTimer(duration: 600, willFireMinutes: 9.833273)
        settle()
        XCTAssertEqual(latestSnapshot()?.isPaused, false)

        writePreferences([(oldTimerID, 2, 900, "MTTimerTimeInterval")])
        monitor.ingestPreferencesChange()
        settle()

        XCTAssertEqual(latestSnapshot()?.isPaused, false)
        XCTAssertEqual(latestSnapshot()?.duration, 600)
    }

    private func startNewTimer(duration: Int, willFireMinutes: Double?) {
        monitor.ingestLogMessage("""
        <MTTimerDurationManager: 0x600001234500> didUpdateTimers fromTimers: (
            "<MTMutableTimer:0x600002345600 TimerID: \(newTimerID), Title: (null), state:Stopped, duration:\(duration), firedDate: (null), dismissedDate: (null), sound: <MTSound:0x1>>"
        ) toTimers: (
            "<MTMutableTimer:0x600002345610 TimerID: \(newTimerID), Title: (null), state:Running, duration:\(duration), firedDate: (null), dismissedDate: (null), sound: <MTSound:0x1>>"
        )
        """)
        if let willFireMinutes {
            monitor.ingestLogMessage("<MTTimerScheduler: 0x600001234570> Timer will fire \(willFireMinutes) minutes from now")
        }
        monitor.ingestLogMessage("<MTATimerCollectionViewController: 0x600001234580> started timer: \(newTimerID)")
    }

    private func writePreferences(_ timers: [(id: String, state: Int, duration: Double, fireClass: String)]) {
        let entries: [[String: Any]] = timers.map { timer in
            ["$MTTimer": [
                "MTTimerID": timer.id,
                "MTTimerDuration": timer.duration,
                "MTTimerState": timer.state,
                "MTTimerFireTimerClass": timer.fireClass
            ] as [String: Any]]
        }
        CFPreferencesSetAppValue("MTTimers" as CFString, ["MTTimers": entries] as CFDictionary, domain)
        CFPreferencesAppSynchronize(domain)
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
}
