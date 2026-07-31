import XCTest
@testable import DynamicNotch

@MainActor
final class NotificationCenterViewModelTests: XCTestCase {
    func testPublishingPayloadAppendsItemAndCountsItUnread() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(title: "Backup nightly", summary: "42 files\nOK"))

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.title, "Backup nightly")
        XCTAssertEqual(viewModel.items.first?.summary, "42 files\nOK")
        XCTAssertFalse(viewModel.items.first?.read ?? true)
        XCTAssertEqual(viewModel.unreadCount, 1)
    }

    func testHighestUnreadLevelReturnsMostSevereAcrossMixedList() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(level: .info))
        monitor.publish(makePayload(level: .error))
        monitor.publish(makePayload(level: .warning))
        monitor.publish(makePayload(level: .success))

        XCTAssertEqual(viewModel.items.count, 4)
        XCTAssertEqual(viewModel.unreadCount, 4)
        XCTAssertEqual(viewModel.highestUnreadLevel, .error)
    }

    func testHighestUnreadLevelIsNilWhenNothingUnread() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        XCTAssertNil(viewModel.highestUnreadLevel)
    }

    func testClearAllEmptiesListAndResetsUnreadCount() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(level: .error))
        monitor.publish(makePayload(level: .warning))
        XCTAssertEqual(viewModel.unreadCount, 2)

        viewModel.clearAll()

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(viewModel.unreadCount, 0)
        XCTAssertNil(viewModel.highestUnreadLevel)
    }

    func testListAndBadgeAreRestoredIdenticallyOnRelaunch() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let firstMonitor = FakeNotificationInboxMonitor()
        let firstViewModel = NotificationCenterViewModel(
            monitor: firstMonitor,
            defaults: defaults,
            now: { fixedDate }
        )
        TestLifetime.retain(firstViewModel)

        firstMonitor.publish(makePayload(title: "Backup", summary: "done", level: .error, source: "backup.sh"))
        firstMonitor.publish(makePayload(title: "CI", summary: "green", level: .info))
        let persistedItems = firstViewModel.items

        let secondMonitor = FakeNotificationInboxMonitor()
        let restoredViewModel = NotificationCenterViewModel(
            monitor: secondMonitor,
            defaults: defaults,
            now: { fixedDate }
        )
        TestLifetime.retain(restoredViewModel)

        XCTAssertEqual(restoredViewModel.items, persistedItems)
        XCTAssertEqual(restoredViewModel.unreadCount, 2)
        XCTAssertEqual(restoredViewModel.highestUnreadLevel, .error)
    }
}

private extension NotificationCenterViewModelTests {
    func makeViewModel(
        monitor: FakeNotificationInboxMonitor,
        defaults: UserDefaults? = nil
    ) -> NotificationCenterViewModel {
        let store = defaults ?? UserDefaults(suiteName: UUID().uuidString)!
        let viewModel = NotificationCenterViewModel(monitor: monitor, defaults: store)
        TestLifetime.retain(viewModel)
        return viewModel
    }

    func makePayload(
        title: String = "Title",
        summary: String = "Summary",
        level: NotificationLevel = .info,
        source: String? = nil,
        icon: String? = nil
    ) -> NotificationPayload {
        NotificationPayload(
            title: title,
            summary: summary,
            level: level,
            source: source,
            icon: icon
        )
    }
}
