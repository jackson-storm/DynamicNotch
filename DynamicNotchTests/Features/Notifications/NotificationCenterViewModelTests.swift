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
    // MARK: - Read / Done / Close (Seam 1 — Slice 3)

    /// Read keeps item in list, marks it read, decrements badge.
    func testReadKeepsItemMarksReadAndDecrementsBadge() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload())
        let id = viewModel.items[0].id
        XCTAssertEqual(viewModel.unreadCount, 1)

        viewModel.markRead(id: id)

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertTrue(viewModel.items[0].read)
        XCTAssertEqual(viewModel.unreadCount, 0)
        XCTAssertFalse(viewModel.isBadgeVisible)
    }

    /// Done removes item from list; decrements badge when item was unread.
    func testDoneRemovesItemAndDecrementsBadgeWhenUnread() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload())
        let id = viewModel.items[0].id
        XCTAssertEqual(viewModel.unreadCount, 1)

        viewModel.markDone(id: id)

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(viewModel.unreadCount, 0)
        XCTAssertFalse(viewModel.isBadgeVisible)
    }

    /// Done removes an already-read item without affecting the badge (it was already 0).
    func testDoneRemovesReadItemWithoutChangingBadge() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload())
        let id = viewModel.items[0].id
        viewModel.markRead(id: id)
        XCTAssertEqual(viewModel.unreadCount, 0)

        viewModel.markDone(id: id)

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(viewModel.unreadCount, 0)
    }

    /// Read is idempotent: calling it twice on the same item does not phantom-decrement the badge.
    func testReadIsIdempotent() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload())
        let id = viewModel.items[0].id
        viewModel.markRead(id: id)
        XCTAssertEqual(viewModel.unreadCount, 0)

        viewModel.markRead(id: id)

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.unreadCount, 0)
    }

    /// Control scenario (spec §4): 2 unread A and B. Read A → [A(read), B], badge 2→1.
    func testControlScenarioReadA() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(title: "A"))
        monitor.publish(makePayload(title: "B"))
        let idA = viewModel.items[0].id
        XCTAssertEqual(viewModel.unreadCount, 2)

        viewModel.markRead(id: idA)

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertTrue(viewModel.items[0].read)
        XCTAssertFalse(viewModel.items[1].read)
        XCTAssertEqual(viewModel.unreadCount, 1)
    }

    /// Control scenario (spec §4): 2 unread A and B. Done A → [B], badge 2→1.
    func testControlScenarioDoneA() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(title: "A"))
        monitor.publish(makePayload(title: "B"))
        let idA = viewModel.items[0].id
        XCTAssertEqual(viewModel.unreadCount, 2)

        viewModel.markDone(id: idA)

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items[0].title, "B")
        XCTAssertEqual(viewModel.unreadCount, 1)
    }

    /// Control scenario (spec §4): 2 unread A and B. Close A (no VM call) → [A, B], badge 2→2.
    /// A is still unread. Verifies that merely selecting a row changes no state.
    func testControlScenarioCloseALeavesStateUnchanged() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(title: "A"))
        monitor.publish(makePayload(title: "B"))
        // Close and Open are navigation-only: no VM method is called.
        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertFalse(viewModel.items[0].read)
        XCTAssertFalse(viewModel.items[1].read)
        XCTAssertEqual(viewModel.unreadCount, 2)
    }

    /// markRead persists: restarting the VM on the same UserDefaults preserves read=true.
    func testMarkReadPersistsAcrossRelaunch() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!

        let monitor1 = FakeNotificationInboxMonitor()
        let vm1 = NotificationCenterViewModel(monitor: monitor1, defaults: defaults)
        TestLifetime.retain(vm1)
        monitor1.publish(makePayload())
        let id = vm1.items[0].id
        vm1.markRead(id: id)

        let monitor2 = FakeNotificationInboxMonitor()
        let vm2 = NotificationCenterViewModel(monitor: monitor2, defaults: defaults)
        TestLifetime.retain(vm2)

        XCTAssertEqual(vm2.items.count, 1)
        XCTAssertTrue(vm2.items[0].read)
        XCTAssertEqual(vm2.unreadCount, 0)
    }

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

    // MARK: - Coalescence by source (Seam 1 — Slice 4)

    /// Second drop of a known source replaces content and moves the item to head.
    /// The item count must not grow, and the UUID must be preserved (detail views key by id).
    func testCoalescingKnownSourceReplacesContentAndMovesToHead() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(title: "Initial", summary: "v1", level: .info, source: "backup.sh"))
        let originalId = viewModel.items[0].id

        monitor.publish(makePayload(title: "Updated", summary: "v2", level: .success, source: "backup.sh"))

        XCTAssertEqual(viewModel.items.count, 1, "coalesce must not grow the list")
        XCTAssertEqual(viewModel.items[0].id, originalId, "coalesce must preserve the item id")
        XCTAssertEqual(viewModel.items[0].title, "Updated")
        XCTAssertEqual(viewModel.items[0].summary, "v2")
        XCTAssertEqual(viewModel.items[0].level, .success)
    }

    /// Coalescing updates receivedAt to the timestamp of the second drop, not the first.
    func testCoalescingUpdatesReceivedAt() {
        let monitor = FakeNotificationInboxMonitor()
        let first = Date(timeIntervalSince1970: 1_000_000)
        let second = Date(timeIntervalSince1970: 2_000_000)
        var dates = [first, second]
        let viewModel = makeViewModel(monitor: monitor, now: { dates.removeFirst() })

        monitor.publish(makePayload(source: "backup.sh"))
        monitor.publish(makePayload(source: "backup.sh"))

        XCTAssertEqual(viewModel.items[0].receivedAt, second)
    }

    /// Coalescing a read item re-marks it unread and increments the badge (the badge-critical path).
    func testCoalescingReadItemRepassesUnreadAndIncrementsBadge() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(source: "backup.sh"))
        let id = viewModel.items[0].id
        viewModel.markRead(id: id)
        XCTAssertEqual(viewModel.unreadCount, 0)

        monitor.publish(makePayload(source: "backup.sh"))

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertFalse(viewModel.items[0].read)
        XCTAssertEqual(viewModel.unreadCount, 1)
        XCTAssertTrue(viewModel.isBadgeVisible)
    }

    /// Coalescing an already-unread item keeps it unread and the badge count unchanged.
    func testCoalescingUnreadItemRemainsUnreadWithUnchangedBadge() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(source: "backup.sh"))
        XCTAssertEqual(viewModel.unreadCount, 1)

        monitor.publish(makePayload(source: "backup.sh"))

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertFalse(viewModel.items[0].read)
        XCTAssertEqual(viewModel.unreadCount, 1)
    }

    /// Two drops without source are always appended and must never coalesce with each other.
    func testTwoDropsWithoutSourceProduceTwoDistinctItems() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(title: "First", summary: "A"))
        monitor.publish(makePayload(title: "Second", summary: "B"))

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertNotEqual(viewModel.items[0].id, viewModel.items[1].id)
    }

    /// A coalesced item must be promoted to head even when another item was more recently added.
    func testCoalescingMovesItemToHeadWhenNotAlreadyFirst() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(title: "Older", summary: "A", source: "backup.sh"))
        monitor.publish(makePayload(title: "Newer", summary: "B", source: "ci.sh"))
        XCTAssertEqual(viewModel.items[0].source, "backup.sh")
        XCTAssertEqual(viewModel.items[1].source, "ci.sh")

        monitor.publish(makePayload(title: "Updated", summary: "A2", source: "backup.sh"))

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertEqual(viewModel.items[0].source, "backup.sh", "coalesced item must be at head")
        XCTAssertEqual(viewModel.items[0].title, "Updated")
        XCTAssertEqual(viewModel.items[1].source, "ci.sh")
    }

    /// highestUnreadLevel reflects the coalesced item's new level.
    func testCoalescingUpdatesHighestUnreadLevel() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.publish(makePayload(level: .info, source: "backup.sh"))
        XCTAssertEqual(viewModel.highestUnreadLevel, .info)

        monitor.publish(makePayload(level: .error, source: "backup.sh"))

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.highestUnreadLevel, .error)
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

    // MARK: - Arrival banner (Seam 2 — Slice 5)

    /// A payload arriving before completeDrain() (drain items) must NOT fire onNewItem.
    func testOnNewItemIsSuppressedBeforeDrainCompletes() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        var received: [NotificationItem] = []
        viewModel.onNewItem = { received.append($0) }

        monitor.publish(makePayload(title: "Drain item"))

        XCTAssertTrue(received.isEmpty, "drain item must not trigger onNewItem")
    }

    /// A payload arriving after completeDrain() (live item) must fire onNewItem once.
    func testOnNewItemFiresAfterDrainCompletes() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        var received: [NotificationItem] = []
        viewModel.onNewItem = { received.append($0) }

        monitor.completeDrain()
        monitor.publish(makePayload(title: "Live item"))

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received[0].title, "Live item")
    }

    /// Three live drops in quick succession fire onNewItem three times with distinct items.
    func testOnNewItemFiresForEachDropInBurst() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        var received: [NotificationItem] = []
        viewModel.onNewItem = { received.append($0) }

        monitor.completeDrain()
        monitor.publish(makePayload(title: "A"))
        monitor.publish(makePayload(title: "B"))
        monitor.publish(makePayload(title: "C"))

        XCTAssertEqual(received.count, 3)
        XCTAssertEqual(received.map(\.title), ["A", "B", "C"])
    }

    /// markRead, markDone, and clearAll do not trigger onNewItem.
    func testOnNewItemIsNotFiredByReadDoneClearAll() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.completeDrain()
        monitor.publish(makePayload(title: "Item"))

        var receivedAfterActions: [NotificationItem] = []
        viewModel.onNewItem = { receivedAfterActions.append($0) }

        let id = viewModel.items[0].id
        viewModel.markRead(id: id)
        viewModel.markDone(id: id)
        viewModel.clearAll()

        XCTAssertTrue(receivedAfterActions.isEmpty)
    }

    /// A coalescing update (known source, live) also fires onNewItem with the updated item.
    func testOnNewItemFiresOnCoalescenceWithUpdatedContent() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        monitor.completeDrain()
        monitor.publish(makePayload(title: "Initial", level: .info, source: "backup.sh"))

        var received: [NotificationItem] = []
        viewModel.onNewItem = { received.append($0) }

        monitor.publish(makePayload(title: "Updated", level: .error, source: "backup.sh"))

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received[0].title, "Updated")
        XCTAssertEqual(received[0].level, .error)
    }

    /// onNewItem passes the correct title, summary, and level from the payload.
    func testOnNewItemPassesCorrectItemFields() {
        let monitor = FakeNotificationInboxMonitor()
        let viewModel = makeViewModel(monitor: monitor)

        var received: NotificationItem?
        viewModel.onNewItem = { received = $0 }

        monitor.completeDrain()
        monitor.publish(makePayload(title: "Deploy failed", summary: "prod-api crashed", level: .error))

        XCTAssertEqual(received?.title, "Deploy failed")
        XCTAssertEqual(received?.summary, "prod-api crashed")
        XCTAssertEqual(received?.level, .error)
    }
}

private extension NotificationCenterViewModelTests {
    func makeViewModel(
        monitor: FakeNotificationInboxMonitor,
        defaults: UserDefaults? = nil,
        now: @escaping () -> Date = { Date() }
    ) -> NotificationCenterViewModel {
        let store = defaults ?? UserDefaults(suiteName: UUID().uuidString)!
        let viewModel = NotificationCenterViewModel(monitor: monitor, defaults: store, now: now)
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
