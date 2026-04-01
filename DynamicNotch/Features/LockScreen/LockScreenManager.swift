import Foundation
internal import AppKit
import Combine

@MainActor
final class LockScreenManager: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var isPreparingLock = false
    @Published private(set) var isLockIdle = true
    @Published var event: LockScreenEvent?

    private let service: any LockScreenMonitoring
    private let soundPlayer: any LockScreenSoundPlaying
    private let defaults: UserDefaults
    private let unlockCollapseDelay: TimeInterval
    private let idleResetDelay: TimeInterval

    private var hasStartedMonitoring = false
    private var unlockWorkItem: DispatchWorkItem?
    private var workspaceObservers: [NSObjectProtocol] = []

    init(
        service: (any LockScreenMonitoring)? = nil,
        soundPlayer: (any LockScreenSoundPlaying)? = nil,
        defaults: UserDefaults = .standard,
        unlockCollapseDelay: TimeInterval = 0.82,
        idleResetDelay: TimeInterval = 0.82
    ) {
        self.service = service ?? DistributedLockScreenMonitoringService()
        self.soundPlayer = soundPlayer ?? LockScreenSoundPlayer()
        self.defaults = defaults
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
        registerWorkspaceObservers()
    }

    func stopMonitoring() {
        guard hasStartedMonitoring else { return }
        hasStartedMonitoring = false

        unlockWorkItem?.cancel()
        unlockWorkItem = nil
        removeWorkspaceObservers()
        service.stopMonitoring()
    }

    var isTransitioning: Bool {
        isLocked || isPreparingLock || !isLockIdle
    }

    var isShowingLockPresentation: Bool {
        isLocked || isPreparingLock
    }

    #if DEBUG
    func setDebugLockState(_ locked: Bool) {
        unlockWorkItem?.cancel()
        unlockWorkItem = nil
        isPreparingLock = false
        isLocked = locked
        isLockIdle = !locked
    }
    #endif

    private func registerWorkspaceObservers() {
        guard workspaceObservers.isEmpty else { return }

        let center = NSWorkspace.shared.notificationCenter

        workspaceObservers = [
            center.addObserver(
                forName: NSWorkspace.sessionDidResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleSessionDidResignActive()
                }
            },
            center.addObserver(
                forName: NSWorkspace.sessionDidBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleSessionDidBecomeActive()
                }
            }
        ]
    }

    private func removeWorkspaceObservers() {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach(center.removeObserver)
        workspaceObservers.removeAll()
    }

    private func handleSessionDidResignActive() {
        guard !isLocked else { return }

        unlockWorkItem?.cancel()
        unlockWorkItem = nil
        isPreparingLock = true
        isLockIdle = false
    }

    private func handleSessionDidBecomeActive() {
        guard !isLocked else { return }

        if isPreparingLock {
            isPreparingLock = false
        }

        guard unlockWorkItem == nil else { return }
        isLockIdle = true
    }

    private func apply(lockState locked: Bool) {
        guard isLocked != locked else { return }

        unlockWorkItem?.cancel()
        unlockWorkItem = nil

        if locked {
            if LockScreenSettings.isSoundEnabled(in: defaults) {
                soundPlayer.playLock()
            }
            isPreparingLock = false
            isLocked = true
            isLockIdle = false
            event = .started
            return
        }

        if LockScreenSettings.isSoundEnabled(in: defaults) {
            soundPlayer.playUnlock()
        }
        isLocked = false
        isPreparingLock = false
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
