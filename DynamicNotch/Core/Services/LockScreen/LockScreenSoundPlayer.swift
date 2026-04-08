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
    private let defaults: UserDefaults
    private var players: [SoundAsset: AVAudioPlayer] = [:]
    private var customPlayers: [SoundAsset: AVAudioPlayer] = [:]
    private var customPlayerURLs: [SoundAsset: URL] = [:]

    init(bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        self.bundle = bundle
        self.defaults = defaults
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
        guard let player = customPlayerIfAvailable(for: asset) ?? player(for: asset) else {
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

    private func customPlayerIfAvailable(for asset: SoundAsset) -> AVAudioPlayer? {
        guard let url = customSoundURL(for: asset) else {
            customPlayers[asset] = nil
            customPlayerURLs[asset] = nil
            return nil
        }

        if customPlayerURLs[asset] == url, let customPlayer = customPlayers[asset] {
            return customPlayer
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            customPlayers[asset] = player
            customPlayerURLs[asset] = url
            return player
        } catch {
            customPlayers[asset] = nil
            customPlayerURLs[asset] = nil
            return nil
        }
    }

    private func customSoundURL(for asset: SoundAsset) -> URL? {
        let path: String?

        switch asset {
        case .lock:
            path = LockScreenSettings.customLockSoundPath(in: defaults)
                ?? LockScreenSettings.legacyCustomSoundPath(in: defaults)
        case .unlock:
            path = LockScreenSettings.customUnlockSoundPath(in: defaults)
                ?? LockScreenSettings.legacyCustomSoundPath(in: defaults)
        }

        guard let path else {
            return nil
        }

        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        return url
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
