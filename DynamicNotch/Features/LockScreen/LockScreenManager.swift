import Foundation
import AppKit
import Combine

enum LockScreenSettings {
    static let liveActivityKey = "isLockScreenLiveActivityEnabled"
    static let mediaPanelKey = "isLockScreenMediaPanelEnabled"

    static func isLiveActivityEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: liveActivityKey, defaultValue: true, in: defaults)
    }

    static func isMediaPanelEnabled(in defaults: UserDefaults = .standard) -> Bool {
        resolvedBoolean(forKey: mediaPanelKey, defaultValue: true, in: defaults)
    }

    private static func resolvedBoolean(
        forKey key: String,
        defaultValue: Bool,
        in defaults: UserDefaults
    ) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }

        return defaults.bool(forKey: key)
    }
}

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

final class InactiveLockScreenMonitoringService: LockScreenMonitoring {
    var onLockStateChange: ((Bool) -> Void)?

    func startMonitoring() {}
    func stopMonitoring() {}
}

@MainActor
final class LockScreenManager: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var isLockIdle = true
    @Published var event: LockScreenEvent?

    private let service: any LockScreenMonitoring
    private let unlockCollapseDelay: TimeInterval
    private let idleResetDelay: TimeInterval

    private var hasStartedMonitoring = false
    private var unlockWorkItem: DispatchWorkItem?

    init(
        service: (any LockScreenMonitoring)? = nil,
        unlockCollapseDelay: TimeInterval = 0.82,
        idleResetDelay: TimeInterval = 0.82
    ) {
        self.service = service ?? DistributedLockScreenMonitoringService()
        self.unlockCollapseDelay = unlockCollapseDelay
        self.idleResetDelay = idleResetDelay

        self.service.onLockStateChange = { [weak self] isLocked in
            DispatchQueue.main.async { [weak self] in
                self?.apply(lockState: isLocked)
            }
        }
    }

    func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true
        service.startMonitoring()
    }

    func stopMonitoring() {
        guard hasStartedMonitoring else { return }
        hasStartedMonitoring = false

        unlockWorkItem?.cancel()
        unlockWorkItem = nil
        service.stopMonitoring()
    }

    var isTransitioning: Bool {
        isLocked || !isLockIdle
    }

    private func apply(lockState locked: Bool) {
        guard isLocked != locked else { return }

        unlockWorkItem?.cancel()
        unlockWorkItem = nil

        if locked {
            isLocked = true
            isLockIdle = false
            event = .started
            return
        }

        isLocked = false
        isLockIdle = false

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isLockIdle = true
            self.event = .stopped
        }

        unlockWorkItem = workItem
        let delay = max(unlockCollapseDelay, idleResetDelay)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    deinit {
        unlockWorkItem?.cancel()
    }
}
