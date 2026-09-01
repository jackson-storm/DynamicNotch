import Foundation

final class DistributedLockScreenMonitoringService: LockScreenMonitoring {
    var onLockStateChange: ((Bool) -> Void)?

    private let center = DistributedNotificationCenter.default()
    private var observers: [NSObjectProtocol] = []
    private var isMonitoring = false

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        observers = [
            center.addObserver(
                forName: Notification.Name("com.apple.screenIsLocked"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.onLockStateChange?(true)
            },
            center.addObserver(
                forName: Notification.Name("com.apple.screenIsUnlocked"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.onLockStateChange?(false)
            }
        ]
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        observers.forEach(center.removeObserver)
        observers.removeAll()
    }

    deinit {
        stopMonitoring()
    }
}
