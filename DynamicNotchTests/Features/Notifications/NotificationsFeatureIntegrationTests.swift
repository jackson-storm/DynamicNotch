import NotificationContract
import XCTest
@testable import DynamicNotch

/// End-to-end wiring of the two seams: a real `NotificationInboxMonitor` feeding a real
/// `NotificationCenterViewModel`. Covers acceptance criterion #1 (a valid drop appears in the
/// list and the file is consumed) at the object level — the SwiftUI page is out of test scope.
/// This is the only test that exercises the VM's `onPayload` thread-hop against the real
/// monitor queue, which the isolated seam tests (raw closure / fake monitor) do not.
@MainActor
final class NotificationsFeatureIntegrationTests: XCTestCase {
    func testValidDropFlowsThroughRealMonitorIntoViewModelAndFileIsConsumed() async {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let viewModel = NotificationCenterViewModel(
            monitor: NotificationInboxMonitor(inboxDirectory: inbox, retryDelay: 0),
            defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()

        atomicDrop(
            ["title": "Backup nightly", "summary": "42 files\nOK", "level": "success", "source": "backup.sh"],
            in: inbox
        )

        await assertEventually(timeout: 10.0) {
            await MainActor.run { viewModel.items.count == 1 }
        }

        let item = viewModel.items.first
        XCTAssertEqual(item?.title, "Backup nightly")
        XCTAssertEqual(item?.summary, "42 files\nOK")
        XCTAssertEqual(item?.source, "backup.sh")
        XCTAssertEqual(item?.level, .success)
        XCTAssertFalse(item?.read ?? true)
        XCTAssertEqual(viewModel.unreadCount, 1)
        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)

        viewModel.stopMonitoring()
    }
}
