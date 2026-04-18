import Foundation

protocol ClockTimerMonitoring: AnyObject {
    var onSnapshotChange: ((ClockTimerSnapshot?) -> Void)? { get set }

    func startMonitoring()
    func stopMonitoring()
}
