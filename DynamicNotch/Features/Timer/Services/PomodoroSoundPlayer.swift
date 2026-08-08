internal import AppKit

@MainActor
final class PomodoroSoundPlayer {
    private let tickingSound = PomodoroSoundPlayer.sound(named: "ticking")
    private let windUpSound = PomodoroSoundPlayer.sound(named: "windup")
    private let dingSound = PomodoroSoundPlayer.sound(named: "ding")
    private var delayedTickingTask: Task<Void, Never>?

    init() {
        tickingSound?.loops = true
        tickingSound?.volume = 0.45
        windUpSound?.volume = 0.7
        dingSound?.volume = 0.7
    }

    func startTicking(withWindUp: Bool) {
        delayedTickingTask?.cancel()
        tickingSound?.stop()

        guard withWindUp else {
            tickingSound?.play()
            return
        }

        windUpSound?.stop()
        windUpSound?.play()
        delayedTickingTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(920))
            guard !Task.isCancelled else { return }
            self?.tickingSound?.play()
        }
    }

    func pauseTicking() {
        delayedTickingTask?.cancel()
        delayedTickingTask = nil
        tickingSound?.pause()
    }

    func playCompletion() {
        dingSound?.stop()
        dingSound?.play()
    }

    func stop() {
        delayedTickingTask?.cancel()
        delayedTickingTask = nil
        tickingSound?.stop()
        windUpSound?.stop()
        dingSound?.stop()
    }

    private static func sound(named name: String) -> NSSound? {
        guard let data = NSDataAsset(name: name)?.data else { return nil }
        return NSSound(data: data)
    }
}
