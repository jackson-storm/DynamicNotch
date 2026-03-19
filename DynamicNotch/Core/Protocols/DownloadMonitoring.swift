import Foundation

protocol DownloadMonitoring: AnyObject {
    var onSnapshotChange: (([DownloadModel]) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}
