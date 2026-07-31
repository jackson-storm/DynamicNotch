import Foundation

/// No-op inbox monitor for DEBUG factories and previews: never watches the real inbox
/// directory and never emits a payload. Mirrors `InactiveDownloadMonitor`, and keeps debug
/// coordinators from racing the app's real monitor over the same `inbox/` files.
final class InactiveNotificationInboxMonitor: NotificationInboxMonitoring {
    var onPayload: ((NotificationPayload) -> Void)?

    func startMonitoring() {}
    func stopMonitoring() {}
}
