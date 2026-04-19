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
    @Published private(set) var formattedTime: String = "0:00"

    private let monitor: any ClockTimerMonitoring
    private let controller: any ClockTimerControlling
    private var hasStartedMonitoring = false
    private var formattedTimeTask: Task<Void, Never>?

    init(
        monitor: any ClockTimerMonitoring,
        controller: (any ClockTimerControlling)? = nil
    ) {
        self.monitor = monitor
        self.controller = controller ?? InactiveClockTimerController()
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
        stopFormattedTimeUpdates()
    }

    func togglePauseResume() async -> Bool {
        await controller.togglePauseResume()
    }

    func stopTimer() async -> Bool {
        await controller.stopTimer()
    }

    func formatTime(_ remainingTime: TimeInterval) -> String {
        let displaySeconds = max(0, Int(ceil(remainingTime)))

        if displaySeconds < 3600 {
            return minuteSecondFormatter.string(from: TimeInterval(displaySeconds)) ?? "0:00"
        }

        return abbreviatedHourMinuteTime(displaySeconds)
    }

    private func abbreviatedHourMinuteTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if minutes > 0 {
            return "\(hours)h \(minutes)min"
        }

        return "\(hours)h"
    }

    private let minuteSecondFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        return formatter
    }()

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
        refreshFormattedTime()
        updateFormattedTimeTask(for: nextSnapshot)

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

    func updateFormattedTimeTask(for snapshot: ClockTimerSnapshot?) {
        guard let snapshot else {
            stopFormattedTimeUpdates()
            return
        }

        guard snapshot.isPaused == false else {
            stopFormattedTimeUpdates()
            return
        }

        guard formattedTimeTask == nil else { return }

        formattedTimeTask = Task { [weak self] in
            while Task.isCancelled == false {
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard Task.isCancelled == false else { break }
                self?.refreshFormattedTime()
            }
        }
    }

    func stopFormattedTimeUpdates() {
        formattedTimeTask?.cancel()
        formattedTimeTask = nil
    }

    func refreshFormattedTime() {
        let remainingTime = snapshot?.remainingTime(at: .now) ?? 0
        formattedTime = formatTime(remainingTime)
    }
}
