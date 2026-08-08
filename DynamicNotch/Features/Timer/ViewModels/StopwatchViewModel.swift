import Combine
import Foundation

enum StopwatchState: Equatable {
    case stopped
    case running
    case paused
}

@MainActor
final class StopwatchViewModel: ObservableObject {
    @Published private(set) var state: StopwatchState = .stopped
    @Published private(set) var elapsedTime: TimeInterval = 0

    private var accumulatedTime: TimeInterval = 0
    private var startedAt: Date?
    private var updateTask: Task<Void, Never>?

    func startOrResume() {
        guard state != .running else { return }
        startedAt = Date()
        state = .running
        startUpdating()
    }

    func pause() {
        guard state == .running else { return }
        accumulatedTime = elapsed(at: Date())
        elapsedTime = accumulatedTime
        startedAt = nil
        state = .paused
        cancelUpdating()
    }

    func reset() {
        cancelUpdating()
        accumulatedTime = 0
        startedAt = nil
        elapsedTime = 0
        state = .stopped
    }

    func stop() {
        reset()
    }

    func elapsed(at date: Date) -> TimeInterval {
        guard state == .running, let startedAt else { return accumulatedTime }
        return accumulatedTime + max(0, date.timeIntervalSince(startedAt))
    }

    func formattedElapsed(at date: Date = .now, includesFraction: Bool = true) -> String {
        let elapsed = max(0, elapsed(at: date))
        let totalSeconds = Int(elapsed)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let fraction = min(99, Int((elapsed - floor(elapsed)) * 100))

        if hours > 0 {
            return includesFraction
                ? String(format: "%02d:%02d:%02d.%02d", hours, minutes, seconds, fraction)
                : String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return includesFraction
            ? String(format: "%02d:%02d.%02d", minutes, seconds, fraction)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    private func startUpdating() {
        cancelUpdating()
        updateTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.elapsedTime = self.elapsed(at: Date())
                try? await Task.sleep(for: .milliseconds(20))
            }
        }
    }

    private func cancelUpdating() {
        updateTask?.cancel()
        updateTask = nil
    }
}
