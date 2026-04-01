import Foundation

final class InactiveLockScreenMonitoringService: LockScreenMonitoring {
    var onLockStateChange: ((Bool) -> Void)?

    func startMonitoring() {}
    func stopMonitoring() {}
}
