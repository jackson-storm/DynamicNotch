internal import AppKit

@MainActor
final class PomodoroSoundPlayer {
    private let tickingSound = PomodoroSoundPlayer.loadSound(named: "ticking")
    private let windUpSound = PomodoroSoundPlayer.loadSound(named: "windup")
    private let completionSound = PomodoroSoundPlayer.loadSound(named: "ding")
    private var delayedTickTask: Task<Void, Never>?

    init() {
        tickingSound?.loops = true
        tickingSound?.volume = 0.45
        windUpSound?.volume = 0.7
        completionSound?.volume = 0.7
    }

    func startTicking(withWindUp: Bool) {
        delayedTickTask?.cancel()
        delayedTickTask = nil
        tickingSound?.stop()

        guard withWindUp else {
            tickingSound?.play()
            return
        }

        windUpSound?.stop()
        windUpSound?.play()
        delayedTickTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(920))
            guard !Task.isCancelled else { return }
            self?.tickingSound?.play()
        }
    }

    func pauseTicking() {
        delayedTickTask?.cancel()
        delayedTickTask = nil
        tickingSound?.pause()
    }

    func playCompletion() {
        completionSound?.stop()
        completionSound?.play()
    }

    func stopAll() {
        delayedTickTask?.cancel()
        delayedTickTask = nil
        tickingSound?.stop()
        windUpSound?.stop()
        completionSound?.stop()
    }

    private static func loadSound(named name: String) -> NSSound? {
        guard let data = NSDataAsset(name: name)?.data else { return nil }
        return NSSound(data: data)
    }
}
