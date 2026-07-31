import Combine
import Foundation

/// Single source of truth for the Notifications feature: owns the list, the read/unread
/// state, the unread count and the highest unread severity. The inbox monitor feeds it
/// payloads; the badge and the carousel page both render from it.
@MainActor
final class NotificationCenterViewModel: ObservableObject {
    @Published private(set) var items: [NotificationItem] = [] {
        didSet { onChange?() }
    }

    /// Relayed by the notch coordinator to show/hide the ambient badge. Firing on
    /// assignment (`didSet` below) is deliberate: the VM restores persisted items in
    /// `init`, then the coordinator wires `onChange`, which must immediately reflect a
    /// restored unread item so the badge is current at launch — without a retroactive banner.
    var onChange: (() -> Void)? {
        didSet { onChange?() }
    }

    private static let persistedItemsKey = "settings.notifications.persistedItems"

    private let monitor: any NotificationInboxMonitoring
    private let defaults: UserDefaults
    private let now: () -> Date

    var unreadCount: Int {
        items.reduce(into: 0) { count, item in
            if !item.read { count += 1 }
        }
    }

    /// Most severe level among unread items, or `nil` when nothing is unread.
    /// Drives the badge tint (error > warning > success > info).
    var highestUnreadLevel: NotificationLevel? {
        items.lazy.filter { !$0.read }.map(\.level).max()
    }

    /// The ambient badge shows iff there is at least one unread notification. Read items
    /// left in the list keep it hidden — the list stays reachable through the carousel.
    /// Slice 6 will additionally gate this on the feature toggle.
    var isBadgeVisible: Bool {
        unreadCount > 0
    }

    init(
        monitor: any NotificationInboxMonitoring,
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = { Date() }
    ) {
        self.monitor = monitor
        self.defaults = defaults
        self.now = now

        restorePersistedItems()

        self.monitor.onPayload = { [weak self] payload in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.add(payload: payload)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.add(payload: payload)
                }
            }
        }
    }

    func startMonitoring() {
        monitor.startMonitoring()
    }

    func stopMonitoring() {
        monitor.stopMonitoring()
    }

    func add(payload: NotificationPayload) {
        let item = NotificationItem(
            id: UUID(),
            title: payload.title,
            summary: payload.summary,
            level: payload.level,
            source: payload.source,
            icon: payload.icon,
            receivedAt: now(),
            read: false
        )

        items.append(item)
        persistItems()
    }

    /// "Vider" — drops the whole list, taking the badge to zero.
    func clearAll() {
        items.removeAll()
        persistItems()
    }
}

private extension NotificationCenterViewModel {
    func persistItems() {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: Self.persistedItemsKey)
        } catch {
            defaults.removeObject(forKey: Self.persistedItemsKey)
        }
    }

    func restorePersistedItems() {
        guard let data = defaults.data(forKey: Self.persistedItemsKey) else {
            return
        }

        do {
            items = try JSONDecoder().decode([NotificationItem].self, from: data)
        } catch {
            defaults.removeObject(forKey: Self.persistedItemsKey)
        }
    }
}
