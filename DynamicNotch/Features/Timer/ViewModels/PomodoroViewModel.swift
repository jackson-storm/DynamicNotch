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

    var symbolName: String {
        switch self {
        case .focus: "brain.head.profile"
        case .shortBreak, .longBreak: "cup.and.saucer.fill"
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
    private var sessionDuration: TimeInterval
    private var deadline: Date?
    private var updateTask: Task<Void, Never>?
    private var soundsEnabled: Bool
    private let soundPlayer = PomodoroSoundPlayer()

    private init(defaults: UserDefaults = .standard) {
        let focusMinutes = Self.savedMinutes(for: .focus, defaults: defaults)
        let shortBreakMinutes = Self.savedMinutes(for: .shortBreak, defaults: defaults)
        let longBreakMinutes = Self.savedMinutes(for: .longBreak, defaults: defaults)

        durations = [
            .focus: focusMinutes,
            .shortBreak: shortBreakMinutes,
            .longBreak: longBreakMinutes
        ]
        sessionDuration = TimeInterval(focusMinutes * 60)
        remainingTime = sessionDuration
        soundsEnabled = defaults.object(forKey: Self.soundsKey) as? Bool ?? true
    }

    deinit {
        updateTask?.cancel()
    }

    var formattedRemainingTime: String {
        let seconds = max(0, Int(ceil(remainingTime)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var progress: Double {
        guard sessionDuration > 0 else { return 0 }
        return min(max(1 - (remainingTime / sessionDuration), 0), 1)
    }

    func durationMinutes(for phase: PomodoroPhase) -> Int {
        durations[phase] ?? Self.defaultMinutes(for: phase)
    }

    func startOrResume() {
        guard state != .running else { return }

        let beginsNewSession = state == .stopped
        if remainingTime <= 0 {
            loadCurrentPhaseDuration()
        }

        state = .running
        deadline = Date().addingTimeInterval(remainingTime)
        if soundsEnabled {
            soundPlayer.startTicking(withWindUp: beginsNewSession)
        }
        beginUpdates()
    }

    func pause() {
        guard state == .running else { return }
        refreshRemainingTime(at: Date())
        state = .paused
        deadline = nil
        cancelUpdates()
        soundPlayer.pauseTicking()
    }

    func reset() {
        cancelUpdates()
        soundPlayer.stopAll()
        phase = .focus
        state = .stopped
        completedFocusSessions = 0
        loadCurrentPhaseDuration()
    }

    func skip() {
        let shouldContinue = state == .running
        moveToNextPhase(countCompletedFocus: false)

        if shouldContinue {
            deadline = Date().addingTimeInterval(remainingTime)
            if soundsEnabled {
                soundPlayer.startTicking(withWindUp: false)
            }
            beginUpdates()
        }
    }

    func setSoundsEnabled(_ enabled: Bool) {
        soundsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.soundsKey)

        if !enabled {
            soundPlayer.stopAll()
        } else if state == .running {
            soundPlayer.startTicking(withWindUp: false)
        }
    }

    func updateDuration(minutes: Int, for phase: PomodoroPhase) {
        let value = min(max(minutes, 1), 120)
        durations[phase] = value
        UserDefaults.standard.set(value, forKey: Self.storageKey(for: phase))

        guard self.phase == phase, state == .stopped else { return }
        loadCurrentPhaseDuration()
    }

    private func beginUpdates() {
        cancelUpdates()
        updateTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.refreshRemainingTime(at: Date())
                if self.remainingTime <= 0 {
                    self.finishCurrentPhase()
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func cancelUpdates() {
        updateTask?.cancel()
        updateTask = nil
    }

    private func refreshRemainingTime(at date: Date) {
        guard state == .running, let deadline else { return }
        remainingTime = max(0, deadline.timeIntervalSince(date))
    }

    private func finishCurrentPhase() {
        soundPlayer.playCompletion()
        moveToNextPhase(countCompletedFocus: true)
        deadline = Date().addingTimeInterval(remainingTime)
        if soundsEnabled {
            soundPlayer.startTicking(withWindUp: false)
        }
    }

    private func moveToNextPhase(countCompletedFocus: Bool) {
        if phase == .focus, countCompletedFocus {
            completedFocusSessions += 1
        }

        switch phase {
        case .focus:
            phase = completedFocusSessions > 0 && completedFocusSessions.isMultiple(of: 4)
                ? .longBreak
                : .shortBreak
        case .shortBreak, .longBreak:
            phase = .focus
        }

        loadCurrentPhaseDuration()
    }

    private func loadCurrentPhaseDuration() {
        sessionDuration = TimeInterval(durationMinutes(for: phase) * 60)
        remainingTime = sessionDuration
        deadline = nil
    }

    private static let soundsKey = "pomodoro.rebuilt.soundsEnabled"

    private static func storageKey(for phase: PomodoroPhase) -> String {
        "pomodoro.rebuilt.\(phase.rawValue)Minutes"
    }

    private static func savedMinutes(for phase: PomodoroPhase, defaults: UserDefaults) -> Int {
        let key = storageKey(for: phase)
        guard defaults.object(forKey: key) != nil else {
            return defaultMinutes(for: phase)
        }
        return min(max(defaults.integer(forKey: key), 1), 120)
    }

    private static func defaultMinutes(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .focus: 25
        case .shortBreak: 5
        case .longBreak: 15
        }
    }
}
