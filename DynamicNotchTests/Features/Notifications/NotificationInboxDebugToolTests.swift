#if DEBUG
import XCTest
@testable import DynamicNotch

/// The Debug-tab notification actions write into the real inbox on disk. These tests point
/// the tool at a throwaway inbox and prove that what it drops flows through the genuine
/// monitor exactly as a script's drop would.
final class NotificationInboxDebugToolTests: XCTestCase {
    func testInjectSampleDropIsIngestedByMonitorWithChosenLevel() {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let monitor = NotificationInboxMonitor(inboxDirectory: inbox, retryDelay: 0)
        let expectation = expectation(description: "ingests injected payload")
        var received: NotificationPayload?
        monitor.onPayload = { payload in
            received = payload
            expectation.fulfill()
        }
        monitor.startMonitoring()

        NotificationInboxDebugTool(inboxDirectory: inbox).injectSample(level: .warning)

        wait(for: [expectation], timeout: 10.0)
        monitor.stopMonitoring()

        // What's specific to the tool: it drops a valid payload of the chosen level.
        // File deletion after ingestion is the monitor's concern and is covered by
        // NotificationInboxMonitorIntegrationTests — asserting it here only adds a race,
        // since `onPayload` fires before the monitor removes the file.
        XCTAssertEqual(received?.level, .warning)
        XCTAssertEqual(received?.source, "debug-tab")
        XCTAssertFalse(received?.title.isEmpty ?? true)
        XCTAssertFalse(received?.summary.isEmpty ?? true)
    }

    func testInjectMalformedIsQuarantinedWithoutAPayload() async {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let monitor = NotificationInboxMonitor(inboxDirectory: inbox, retryDelay: 0)
        let receivedCount = UncheckedCounter()
        monitor.onPayload = { _ in receivedCount.increment() }
        monitor.startMonitoring()

        NotificationInboxDebugTool(inboxDirectory: inbox).injectMalformed()

        await assertEventually(timeout: 10.0) { rejectedFileCount(in: inbox) == 1 }
        monitor.stopMonitoring()

        XCTAssertEqual(receivedCount.value, 0)
        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)
    }

    func testClearInboxRemovesPendingAndRejectedButKeepsFolder() {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        // A pending drop plus a quarantined file, as the monitor would leave them.
        atomicDrop(["title": "Pending", "summary": "waiting"], in: inbox)
        let rejected = inbox.appendingPathComponent("rejected", isDirectory: true)
        try? FileManager.default.createDirectory(at: rejected, withIntermediateDirectories: true)
        atomicDropRaw("{ broken ", named: "bad.json", in: rejected)

        NotificationInboxDebugTool(inboxDirectory: inbox).clearInbox()

        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)
        XCTAssertEqual(rejectedFileCount(in: inbox), 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: inbox.path))
    }
}
#endif
