import Foundation

nonisolated protocol DownloadMonitoring: AnyObject, Sendable {
    var onSnapshotChange: (@Sendable ([DownloadModel]) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}
