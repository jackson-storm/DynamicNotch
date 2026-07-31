import Foundation

/// Abstraction over the inbox watcher so the view model can be exercised with a fake.
/// Mirrors `DownloadMonitoring`, but pushes one payload per ingested file rather than a
/// whole-directory snapshot.
protocol NotificationInboxMonitoring: AnyObject {
    var onPayload: ((NotificationPayload) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}
