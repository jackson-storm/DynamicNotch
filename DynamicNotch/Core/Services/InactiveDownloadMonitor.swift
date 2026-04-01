import Foundation

final class InactiveDownloadMonitor: DownloadMonitoring {
    var onSnapshotChange: (([DownloadModel]) -> Void)?

    func startMonitoring() {
        onSnapshotChange?([])
    }

    func stopMonitoring() {}
}
