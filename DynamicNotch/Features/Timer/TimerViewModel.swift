import Combine
import Foundation

enum TimerEvent: Equatable {
    case started
    case updated
    case stopped
}

struct ClockTimerSnapshot: Equatable {
    let identifier: String
    let title: String
    let duration: TimeInterval
    let endDate: Date
    let isPaused: Bool
    let pausedRemaining: TimeInterval?
    let fingerprint: String

    func remainingTime(at date: Date) -> TimeInterval {
        if isPaused, let pausedRemaining {
            return max(0, pausedRemaining)
        }

        return max(0, endDate.timeIntervalSince(date))
    }

    func progress(at date: Date) -> Double {
        let resolvedDuration = max(duration, 1)
        return min(max(1 - (remainingTime(at: date) / resolvedDuration), 0), 1)
    }
}

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var snapshot: ClockTimerSnapshot?
    @Published var event: TimerEvent?

    private let monitor: any ClockTimerMonitoring
    private var hasStartedMonitoring = false

    init(monitor: any ClockTimerMonitoring) {
        self.monitor = monitor
        self.monitor.onSnapshotChange = { [weak self] snapshot in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.apply(snapshot: snapshot)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.apply(snapshot: snapshot)
                }
            }
        }
    }

    var hasActiveTimer: Bool {
        snapshot != nil
    }

    func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true
        monitor.startMonitoring()
    }

    func stopMonitoring() {
        guard hasStartedMonitoring else { return }
        hasStartedMonitoring = false
        monitor.stopMonitoring()
    }

    #if DEBUG
    private var isShowingDebugPreviewSnapshot: Bool { _isShowingDebugPreviewSnapshot }
    private var _isShowingDebugPreviewSnapshot = false

    func showDebugPreviewSnapshotIfNeeded() {
        guard snapshot == nil else { return }
        _isShowingDebugPreviewSnapshot = true
        apply(snapshot: Self.makeDebugPreviewSnapshot(), emitEvent: false)
    }

    func hideDebugPreviewSnapshotIfNeeded() {
        guard _isShowingDebugPreviewSnapshot else { return }
        _isShowingDebugPreviewSnapshot = false
        apply(snapshot: nil, emitEvent: false)
    }

    private static func makeDebugPreviewSnapshot() -> ClockTimerSnapshot {
        ClockTimerSnapshot(
            identifier: "debug.clock.timer",
            title: "Timer",
            duration: 120,
            endDate: .now.addingTimeInterval(120),
            isPaused: false,
            pausedRemaining: nil,
            fingerprint: "debug.clock.timer"
        )
    }
    #endif
}

private extension TimerViewModel {
    func apply(snapshot nextSnapshot: ClockTimerSnapshot?, emitEvent: Bool = true) {
        let previousSnapshot = snapshot
        snapshot = nextSnapshot

        guard emitEvent else { return }

        switch (previousSnapshot, nextSnapshot) {
        case (nil, nil):
            break

        case (nil, .some):
            event = .started

        case (.some, nil):
            event = .stopped

        case let (.some(previousSnapshot), .some(nextSnapshot)):
            event = previousSnapshot.fingerprint == nextSnapshot.fingerprint ? .updated : .started
        }
    }
}
