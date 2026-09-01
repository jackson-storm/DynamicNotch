import AVFoundation
internal import AppKit
import Foundation

@MainActor
protocol TimerSoundPlaying: AnyObject {
    var isPlaying: Bool { get }
    func play(sound: TimerSound, isSoundEnabled: Bool, loop: Bool)
    func stop()
}

extension TimerSoundPlaying {
    func play(sound: TimerSound, isSoundEnabled: Bool = true, loop: Bool = true) {
        play(sound: sound, isSoundEnabled: isSoundEnabled, loop: loop)
    }
}

@MainActor
final class TimerSoundPlayer: NSObject, AVAudioPlayerDelegate, TimerSoundPlaying {
    static let shared = TimerSoundPlayer()

    private var audioPlayer: AVAudioPlayer?
    private var nsSound: NSSound?

    override private init() {
        super.init()
    }

    func play(sound: TimerSound, isSoundEnabled: Bool = true, loop: Bool = true) {
        stop()
        guard isSoundEnabled else { return }

        if let fileURL = sound.fileURL {
            do {
                let player = try AVAudioPlayer(contentsOf: fileURL)
                player.delegate = self
                player.numberOfLoops = loop ? -1 : 0
                player.prepareToPlay()
                player.play()
                self.audioPlayer = player
                return
            } catch {
                // Fallback below
            }
        }

        let fallbackName = (sound == .ping) ? "Ping" : "Glass"
        if let soundObj = NSSound(named: fallbackName) {
            soundObj.loops = loop
            soundObj.play()
            self.nsSound = soundObj
        }
    }

    func stop() {
        if let audioPlayer {
            audioPlayer.stop()
            self.audioPlayer = nil
        }
        if let nsSound {
            nsSound.stop()
            self.nsSound = nil
        }
    }

    var isPlaying: Bool {
        (audioPlayer?.isPlaying ?? false) || (nsSound?.isPlaying ?? false)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if self.audioPlayer === player {
                self.audioPlayer = nil
            }
        }
    }
}
