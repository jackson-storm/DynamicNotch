import Foundation

/// Abstraction over the inbox watcher so the view model can be exercised with a fake.
/// Mirrors `DownloadMonitoring`, but pushes one payload per ingested file rather than a
/// whole-directory snapshot.
protocol NotificationInboxMonitoring: AnyObject {
    var onPayload: ((NotificationPayload) -> Void)? { get set }
    /// Fired once on the main thread after the initial drain scan completes. Any payload
    /// arriving after this point is considered "live" and may trigger a banner.
    var onDrainCompleted: (() -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}
