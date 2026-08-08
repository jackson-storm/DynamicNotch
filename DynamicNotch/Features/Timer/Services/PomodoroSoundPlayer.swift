internal import AppKit

@MainActor
final class PomodoroSoundPlayer {
    private let tickSound = NSSound(named: NSSound.Name("Tink"))
    private var windUpTask: Task<Void, Never>?

    func playTick() {
        tickSound?.stop()
        tickSound?.volume = 0.18
        tickSound?.play()
    }

    func playWindUp() {
        windUpTask?.cancel()
        windUpTask = Task { @MainActor in
            let steps: [(name: String, volume: Float, delay: UInt64)] = [
                ("Pop", 0.22, 150_000_000),
                ("Pop", 0.28, 120_000_000),
                ("Tink", 0.32, 90_000_000),
                ("Tink", 0.38, 70_000_000),
                ("Glass", 0.42, 0)
            ]

            for step in steps {
                guard !Task.isCancelled else { return }
                let sound = NSSound(named: NSSound.Name(step.name))
                sound?.volume = step.volume
                sound?.play()
                if step.delay > 0 {
                    try? await Task.sleep(nanoseconds: step.delay)
                }
            }
        }
    }

    func stop() {
        windUpTask?.cancel()
        windUpTask = nil
        tickSound?.stop()
    }
}
