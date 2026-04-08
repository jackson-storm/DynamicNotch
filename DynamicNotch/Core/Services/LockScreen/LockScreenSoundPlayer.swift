import AVFoundation
import Foundation

protocol LockScreenSoundPlaying: AnyObject {
    func playLock()
    func playUnlock()
}

final class InactiveLockScreenSoundPlayer: LockScreenSoundPlaying {
    func playLock() {}
    func playUnlock() {}
}

final class LockScreenSoundPlayer: LockScreenSoundPlaying {
    private enum SoundAsset: String {
        case lock = "DynamicNotch_lock"
        case unlock = "DynamicNotch_unlock"

        var fileName: String {
            rawValue + ".mp3"
        }
    }

    private let bundle: Bundle
    private var players: [SoundAsset: AVAudioPlayer] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func playLock() {
        play(.lock)
    }

    func playUnlock() {
        play(.unlock)
    }
}

private extension LockScreenSoundPlayer {
    private func play(_ asset: SoundAsset) {
        guard let player = player(for: asset) else {
            return
        }

        player.stop()
        player.currentTime = 0
        player.prepareToPlay()
        player.play()
    }

    private func player(for asset: SoundAsset) -> AVAudioPlayer? {
        if let cachedPlayer = players[asset] {
            return cachedPlayer
        }

        guard let url = soundURL(for: asset) else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[asset] = player
            return player
        } catch {
            return nil
        }
    }

    private func soundURL(for asset: SoundAsset) -> URL? {
        let subdirectories = [nil, "Sounds", "Resources", "Resources/Sounds"]

        for subdirectory in subdirectories {
            if let url = bundle.url(
                forResource: asset.rawValue,
                withExtension: "mp3",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        if let directURL = bundle.url(forResource: asset.fileName, withExtension: nil) {
            return directURL
        }

        guard let resourceURL = bundle.resourceURL,
              let enumerator = FileManager.default.enumerator(
                at: resourceURL,
                includingPropertiesForKeys: nil
              ) else {
            return nil
        }

        while let candidateURL = enumerator.nextObject() as? URL {
            if candidateURL.lastPathComponent == asset.fileName {
                return candidateURL
            }
        }

        return nil
    }
}
