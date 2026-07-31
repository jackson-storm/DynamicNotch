import XCTest
@testable import DynamicNotch

final class NotificationInboxMonitorIntegrationTests: XCTestCase {
    func testValidJSONDropIsIngestedThenFileDeleted() {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let monitor = NotificationInboxMonitor(inboxDirectory: inbox, retryDelay: 0)
        let expectation = expectation(description: "ingests dropped payload")
        var received: NotificationPayload?

        monitor.onPayload = { payload in
            received = payload
            expectation.fulfill()
        }
        monitor.startMonitoring()

        atomicDrop(
            ["title": "Backup nightly", "summary": "42 files\nOK", "level": "success"],
            named: "\(UUID().uuidString).json",
            in: inbox
        )

        wait(for: [expectation], timeout: 10.0)
        monitor.stopMonitoring()

        XCTAssertEqual(received?.title, "Backup nightly")
        XCTAssertEqual(received?.summary, "42 files\nOK")
        XCTAssertEqual(received?.level, .success)
        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)
    }

    func testMalformedJSONIsQuarantinedInRejectedAfterRetry() async {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let monitor = NotificationInboxMonitor(inboxDirectory: inbox, retryDelay: 0)
        let receivedCount = UncheckedCounter()

        monitor.onPayload = { _ in receivedCount.increment() }
        monitor.startMonitoring()

        atomicDropRaw("{ this is definitely not json ", named: "bad.json", in: inbox)

        await assertEventually(timeout: 10.0) { rejectedFileCount(in: inbox) == 1 }
        monitor.stopMonitoring()

        XCTAssertEqual(receivedCount.value, 0)
        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)
    }

    func testDropMissingRequiredFieldIsRejected() async {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let monitor = NotificationInboxMonitor(inboxDirectory: inbox, retryDelay: 0)
        let receivedCount = UncheckedCounter()
        monitor.onPayload = { _ in receivedCount.increment() }
        monitor.startMonitoring()

        // Valid JSON, but no `summary` — must be rejected at parse, not surfaced as a blank row.
        atomicDrop(["title": "No summary here"], named: "incomplete.json", in: inbox)

        await assertEventually(timeout: 10.0) { rejectedFileCount(in: inbox) == 1 }
        monitor.stopMonitoring()

        XCTAssertEqual(receivedCount.value, 0)
        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)
    }

    func testDotfilesAndNonJSONFilesAreIgnored() {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let monitor = NotificationInboxMonitor(inboxDirectory: inbox, retryDelay: 0)
        let expectation = expectation(description: "processes only the eligible drop")
        let receivedTitles = UncheckedTitles()
        monitor.onPayload = { payload in
            receivedTitles.append(payload.title)
            expectation.fulfill()
        }
        monitor.startMonitoring()

        // Neither of these is eligible: a dotfile (in-flight temp) and a non-JSON file.
        atomicDrop(["title": "Hidden", "summary": "x"], named: ".inflight.json", in: inbox)
        atomicDropRaw("not json at all", named: "note.txt", in: inbox)
        // A single eligible drop acts as the sync point.
        atomicDrop(["title": "REAL", "summary": "ok"], named: "real.json", in: inbox)

        wait(for: [expectation], timeout: 10.0)
        monitor.stopMonitoring()

        XCTAssertEqual(receivedTitles.values, ["REAL"])
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: inbox.appendingPathComponent(".inflight.json").path
        ))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: inbox.appendingPathComponent("note.txt").path
        ))
        XCTAssertEqual(rejectedFileCount(in: inbox), 0)
    }

    func testFilesPresentBeforeLaunchAreDrained() {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        // Dropped while "the app was closed" — before the monitor starts.
        atomicDrop(["title": "One", "summary": "a"], named: "one.json", in: inbox)
        atomicDrop(["title": "Two", "summary": "b"], named: "two.json", in: inbox)

        let monitor = NotificationInboxMonitor(inboxDirectory: inbox, retryDelay: 0)
        let expectation = expectation(description: "drains pre-existing files")
        expectation.expectedFulfillmentCount = 2
        let receivedTitles = UncheckedTitles()
        monitor.onPayload = { payload in
            receivedTitles.append(payload.title)
            expectation.fulfill()
        }

        monitor.startMonitoring()

        wait(for: [expectation], timeout: 10.0)
        monitor.stopMonitoring()

        XCTAssertEqual(Set(receivedTitles.values), ["One", "Two"])
        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)
    }
}

/// Thread-safe counter — `onPayload` fires on the monitor's queue while assertions read
/// from the test thread.
final class UncheckedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock(); defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock(); defer { lock.unlock() }
        count += 1
    }
}

/// Thread-safe collector for payload titles received on the monitor's queue.
final class UncheckedTitles: @unchecked Sendable {
    private let lock = NSLock()
    private var titles: [String] = []

    var values: [String] {
        lock.lock(); defer { lock.unlock() }
        return titles
    }

    func append(_ title: String) {
        lock.lock(); defer { lock.unlock() }
        titles.append(title)
    }
}
