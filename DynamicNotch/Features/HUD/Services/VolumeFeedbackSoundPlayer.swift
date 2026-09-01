internal import AppKit
import Foundation

/// Plays the system "pop" that macOS normally produces when the volume is changed
/// with the hardware keys. Because the media-key tap consumes the key event, the
/// system never gets a chance to play it itself, so we reproduce the stock behavior
/// here — including honoring the "Play feedback when volume is changed" preference
/// and the Shift override that inverts it.
final class VolumeFeedbackSoundPlayer {
    private let soundURL: URL?
    private var sound: NSSound?

    private static let feedbackDefaultsKey = "com.apple.sound.beep.feedback"
    private static let candidatePaths = [
        "/System/Library/LoginPlugins/BezelServices.loginPlugin/Contents/Resources/volume.aiff",
        "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/volume.aiff"
    ]

    init() {
        soundURL = Self.candidatePaths
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// Plays the feedback sound when appropriate for a volume key press.
    /// - Parameter shiftHeld: Whether Shift was held. Shift inverts the user's
    ///   "Play feedback when volume is changed" preference, matching stock macOS.
    func playIfNeeded(shiftHeld: Bool) {
        guard shouldPlay(shiftHeld: shiftHeld) else { return }
        play()
    }

    private func shouldPlay(shiftHeld: Bool) -> Bool {
        let appFeedbackEnabled = UserDefaults.standard.object(forKey: "settings.hud.volumeFeedbackSound") as? Bool ?? true
        guard appFeedbackEnabled else { return false }

        // Absent key means the preference has never been toggled, which macOS
        // treats as enabled.
        let feedbackEnabled: Bool
        if UserDefaults.standard.object(forKey: Self.feedbackDefaultsKey) == nil {
            feedbackEnabled = true
        } else {
            feedbackEnabled = UserDefaults.standard.bool(forKey: Self.feedbackDefaultsKey)
        }

        return feedbackEnabled != shiftHeld
    }

    private func play() {
        guard let soundURL else { return }

        if sound == nil {
            sound = NSSound(contentsOf: soundURL, byReference: true)
        }

        guard let sound else { return }

        // Restart from the beginning so rapid key presses each produce a tick.
        if sound.isPlaying {
            sound.stop()
        }
        sound.play()
    }
}
