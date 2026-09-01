import Foundation

nonisolated final class InactiveDownloadMonitor: DownloadMonitoring, @unchecked Sendable {
    var onSnapshotChange: (@Sendable ([DownloadModel]) -> Void)?

    func startMonitoring() {
        onSnapshotChange?([])
    }

    func stopMonitoring() {}
}
