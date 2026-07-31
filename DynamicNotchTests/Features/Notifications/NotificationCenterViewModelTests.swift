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

    func testBadgeIsHiddenWhenListEmpty() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        XCTAssertFalse(viewModel.isBadgeVisible)
    }

    func testBadgeIsVisibleWhenAtLeastOneUnread() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(level: .info))

        XCTAssertTrue(viewModel.isBadgeVisible)
    }

    // isBadgeVisible must track the unread count, not mere presence: a list holding only
    // read items keeps the badge hidden. Slice 2 has no markRead yet, so we seed a persisted
    // read item and let the VM restore it. The key mirrors the VM's private persistence key;
    // the `items.count == 1` guard makes any key drift fail loudly instead of passing vacuously.
    func testBadgeIsHiddenWhenAllItemsAreRead() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let readItem = NotificationItem(
            id: UUID(),
            title: "Backup",
            summary: "done",
            level: .error,
            source: "backup.sh",
            icon: nil,
            receivedAt: Date(timeIntervalSince1970: 1_700_000_000),
            read: true
        )
        let data = try! JSONEncoder().encode([readItem])
        defaults.set(data, forKey: "settings.notifications.persistedItems")

        let viewModel = NotificationCenterViewModel(
            monitor: FakeNotificationInboxMonitor(),
            defaults: defaults
        )
        TestLifetime.retain(viewModel)

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.unreadCount, 0)
        XCTAssertNil(viewModel.highestUnreadLevel)
        XCTAssertFalse(viewModel.isBadgeVisible)
    }

    func testBadgeIsHiddenAfterClearAll() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(level: .error))
        XCTAssertTrue(viewModel.isBadgeVisible)

        viewModel.clearAll()

        XCTAssertFalse(viewModel.isBadgeVisible)
    }

    func testOnChangeFiresImmediatelyOnAssignment() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        var fireCount = 0
        viewModel.onChange = { fireCount += 1 }

        XCTAssertEqual(fireCount, 1)
    }

    func testOnChangeFiresOnMutation() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        var fireCount = 0
        viewModel.onChange = { fireCount += 1 }
        fireCount = 0

        monitor.publish(makePayload())
        XCTAssertEqual(fireCount, 1)

        viewModel.clearAll()
        XCTAssertEqual(fireCount, 2)
    }

    // Load-bearing for launch: a persisted unread item restored at init must make the
    // coordinator show the badge the moment it wires `onChange` (PRD stories 23–25).
    func testOnChangeInitialFireReflectsRestoredUnreadItem() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!

        let firstMonitor = FakeNotificationInboxMonitor()
        let firstViewModel = NotificationCenterViewModel(monitor: firstMonitor, defaults: defaults)
        TestLifetime.retain(firstViewModel)
        firstMonitor.publish(makePayload(level: .error))

        let secondMonitor = FakeNotificationInboxMonitor()
        let restoredViewModel = NotificationCenterViewModel(monitor: secondMonitor, defaults: defaults)
        TestLifetime.retain(restoredViewModel)

        var visibleAtWireTime: Bool?
        restoredViewModel.onChange = { [weak restoredViewModel] in
            visibleAtWireTime = restoredViewModel?.isBadgeVisible
        }

        XCTAssertEqual(visibleAtWireTime, true)
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
