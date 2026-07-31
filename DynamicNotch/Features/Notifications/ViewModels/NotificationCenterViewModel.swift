import Combine
import Foundation
import NotificationContract

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

    /// Called with the affected item each time a live payload (post-drain) is ingested.
    /// Wired by the coordinator to show a temporary arrival banner in the notch.
    var onNewItem: ((NotificationItem) -> Void)?

    /// Presentation state shared with the notch content types: `true` while a single
    /// notification's detail is open in the expanded page. The two content types
    /// (`NotificationsBadgeNotchContent`, `HomePageNotchContent`) read it in their
    /// `expandedSize` to grow the notch so the full payload text fits. It is a plain
    /// stored property (not `@Published`): the resize is driven by `onDetailPresentationChange`
    /// forcing a notch relayout, not by SwiftUI dependency tracking.
    var isDetailPresented: Bool = false {
        didSet {
            guard oldValue != isDetailPresented else { return }
            if !isDetailPresented { detailContentHeight = 0 }
            onDetailPresentationChange?()
        }
    }

    /// Measured absolute height (pt) of the open detail view, reported by the detail view
    /// via `setDetailContentHeight`. The content types use it as the expanded notch height
    /// so the notch fits the text instead of a fixed tall frame. `0` until measured (or
    /// after close), in which case content types fall back to a default height.
    private(set) var detailContentHeight: CGFloat = 0

    /// Wired by the coordinator to relayout the notch when the detail presentation state
    /// or its measured height changes, so the freshly-computed `expandedSize` takes effect.
    var onDetailPresentationChange: (() -> Void)?

    /// Reports the detail view's measured height; relayouts the notch when it changes by
    /// at least a point (rounded to avoid sub-pixel jitter looping the layout).
    func setDetailContentHeight(_ height: CGFloat) {
        let rounded = height.rounded()
        guard rounded > 0, abs(rounded - detailContentHeight) >= 1 else { return }
        detailContentHeight = rounded
        onDetailPresentationChange?()
    }

    /// Suppressed until the initial drain scan completes. Prevents retroactive banners
    /// for notifications that arrived while the app was closed.
    private var suppressBanners = true

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

    /// Set by the coordinator when the user toggles the Notifications feature. Changing
    /// this fires `onChange` so the badge is shown/hidden without any other mutation.
    var isFeatureEnabled: Bool = true {
        didSet { onChange?() }
    }

    /// The ambient badge shows iff there is at least one unread notification AND the feature
    /// is enabled. Read items left in the list keep it hidden — the list stays reachable
    /// through the carousel.
    var isBadgeVisible: Bool {
        unreadCount > 0 && isFeatureEnabled
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

        self.monitor.onDrainCompleted = { [weak self] in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.suppressBanners = false
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.suppressBanners = false
                }
            }
        }
    }

    func startMonitoring() {
        suppressBanners = true
        monitor.startMonitoring()
    }

    func stopMonitoring() {
        monitor.stopMonitoring()
    }

    func add(payload: NotificationPayload) {
        // Normalize blank source to nil so empty-string sources behave like absent.
        let source = payload.source.flatMap {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0
        }

        var newItems = items
        let affectedItem: NotificationItem

        if let source, let index = newItems.firstIndex(where: { $0.source == source }) {
            newItems[index].apply(payload, receivedAt: now())
            let coalesced = newItems.remove(at: index)
            newItems.insert(coalesced, at: 0)
            affectedItem = coalesced
        } else {
            let newItem = NotificationItem(
                id: UUID(),
                title: payload.title,
                summary: payload.summary,
                level: payload.level,
                source: source,
                icon: payload.icon,
                receivedAt: now(),
                read: false
            )
            newItems.append(newItem)
            affectedItem = newItem
        }

        items = newItems
        persistItems()
        if !suppressBanners { onNewItem?(affectedItem) }
    }

    /// Marks the notification read, keeping it in the list. Decrements the badge if it was
    /// unread. Idempotent: calling it on an already-read item is a no-op.
    func markRead(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              !items[index].read else { return }
        items[index].read = true
        persistItems()
    }

    /// Removes the notification from the list entirely. If it was unread, the badge
    /// decrements accordingly (via the recomputed `unreadCount`).
    func markDone(id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        items.removeAll { $0.id == id }
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
