import Combine
import Foundation

enum PomodoroPhase: String, CaseIterable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        }
    }
}

enum PomodoroTimerState: Equatable {
    case stopped
    case running
    case paused
}

@MainActor
final class PomodoroViewModel: ObservableObject {
    static let shared = PomodoroViewModel()

    @Published private(set) var phase: PomodoroPhase = .focus
    @Published private(set) var state: PomodoroTimerState = .stopped
    @Published private(set) var remainingTime: TimeInterval
    @Published private(set) var completedFocusSessions = 0

    private var durations: [PomodoroPhase: Int]
    private var totalDuration: TimeInterval
    private var endDate: Date?
    private var ticker: AnyCancellable?

    private init() {
        let defaults = UserDefaults.standard
        let focus = max(1, defaults.integer(forKey: "pomodoro.focusMinutes") == 0 ? 25 : defaults.integer(forKey: "pomodoro.focusMinutes"))
        let shortBreak = max(1, defaults.integer(forKey: "pomodoro.shortBreakMinutes") == 0 ? 5 : defaults.integer(forKey: "pomodoro.shortBreakMinutes"))
        let longBreak = max(1, defaults.integer(forKey: "pomodoro.longBreakMinutes") == 0 ? 15 : defaults.integer(forKey: "pomodoro.longBreakMinutes"))
        durations = [.focus: focus, .shortBreak: shortBreak, .longBreak: longBreak]
        totalDuration = TimeInterval(focus * 60)
        remainingTime = TimeInterval(focus * 60)
    }

    func startOrResume() {
        guard state != .running else { return }
        if remainingTime <= 0 {
            resetCurrentPhase()
        }
        state = .running
        endDate = Date().addingTimeInterval(remainingTime)
        startTicker()
    }

    func pause() {
        guard state == .running else { return }
        updateRemainingTime()
        state = .paused
        endDate = nil
        ticker?.cancel()
        ticker = nil
    }

    func reset() {
        state = .stopped
        phase = .focus
        completedFocusSessions = 0
        ticker?.cancel()
        ticker = nil
        resetCurrentPhase()
    }

    func skip() {
        advancePhase()
        if state == .running {
            endDate = Date().addingTimeInterval(remainingTime)
            startTicker()
        }
    }

    func updateDuration(minutes: Int, for phase: PomodoroPhase) {
        let clampedMinutes = min(max(minutes, 1), 120)
        durations[phase] = clampedMinutes

        guard self.phase == phase else { return }
        let newTotal = TimeInterval(clampedMinutes * 60)
        let elapsed = max(0, totalDuration - remainingTime)
        totalDuration = newTotal
        remainingTime = max(0, newTotal - elapsed)
        if state == .running {
            endDate = Date().addingTimeInterval(remainingTime)
        }
    }

    var formattedRemainingTime: String {
        let seconds = max(0, Int(ceil(remainingTime)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(max(1 - remainingTime / totalDuration, 0), 1)
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateRemainingTime()
                if self.remainingTime <= 0 {
                    self.completeCurrentPhase()
                }
            }
    }

    private func updateRemainingTime() {
        guard let endDate else { return }
        remainingTime = max(0, endDate.timeIntervalSinceNow)
    }

    private func completeCurrentPhase() {
        if phase == .focus {
            completedFocusSessions += 1
        }
        advancePhase()
        endDate = Date().addingTimeInterval(remainingTime)
    }

    private func advancePhase() {
        switch phase {
        case .focus:
            phase = completedFocusSessions > 0 && completedFocusSessions.isMultiple(of: 4) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            phase = .focus
        }
        resetCurrentPhase()
    }

    private func resetCurrentPhase() {
        totalDuration = TimeInterval((durations[phase] ?? 1) * 60)
        remainingTime = totalDuration
        endDate = nil
    }
}
