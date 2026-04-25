import Foundation
internal import AppKit

struct NowPlayingApplicationPlaybackState: Equatable {
    let bundleIdentifier: String
    let isPlaying: Bool
    let title: String?
    let artist: String?
    let album: String?
    let elapsedTime: TimeInterval?
    let duration: TimeInterval?
    let isShuffled: Bool?
    let repeatMode: NowPlayingRepeatMode?
    let volume: Double?
    let refreshedAt: Date
}

final class NowPlayingApplicationBridge {
    private let youtubeMusicClient = YouTubeMusicRemoteClient()

    func send(_ command: NowPlayingCommand, source: NowPlayingPlaybackSource?) -> Bool {
        guard let bundleIdentifier = source?.preferredBundleIdentifier else { return false }

        switch bundleIdentifier {
        case "com.apple.Music":
            return sendAppleMusic(command)
        case "com.spotify.client":
            return sendSpotify(command)
        case "com.github.th-ch.youtube-music":
            return sendYouTubeMusic(command)
        default:
            return false
        }
    }

    func favoriteState(for source: NowPlayingPlaybackSource?) async -> Bool? {
        guard let bundleIdentifier = source?.preferredBundleIdentifier else { return nil }

        switch bundleIdentifier {
        case "com.apple.Music":
            return await appleMusicFavoriteState()
        case "com.github.th-ch.youtube-music":
            return await youtubeMusicClient.favoriteState()
        default:
            return nil
        }
    }

    func playbackState(for source: NowPlayingPlaybackSource?) async -> NowPlayingApplicationPlaybackState? {
        guard let bundleIdentifier = source?.preferredBundleIdentifier else { return nil }

        switch bundleIdentifier {
        case "com.apple.Music":
            return await appleMusicPlaybackState()
        case "com.spotify.client":
            return await spotifyPlaybackState()
        case "com.github.th-ch.youtube-music":
            return await youtubeMusicClient.playbackState()
        default:
            return nil
        }
    }
}

private extension NowPlayingApplicationBridge {
    func sendAppleMusic(_ command: NowPlayingCommand) -> Bool {
        guard isApplicationRunning(bundleIdentifier: "com.apple.Music") else { return false }
        guard let body = appleMusicCommandBody(for: command) else { return false }

        Task {
            try? await NowPlayingAppleScriptRunner.executeVoid("""
            tell application "Music"
                try
                    \(body)
                end try
            end tell
            """)
        }

        return true
    }

    func sendSpotify(_ command: NowPlayingCommand) -> Bool {
        guard isApplicationRunning(bundleIdentifier: "com.spotify.client") else { return false }
        guard let body = spotifyCommandBody(for: command) else { return false }

        Task {
            try? await NowPlayingAppleScriptRunner.executeVoid("""
            tell application "Spotify"
                try
                    \(body)
                end try
            end tell
            """)
        }

        return true
    }

    func appleMusicPlaybackState() async -> NowPlayingApplicationPlaybackState? {
        guard isApplicationRunning(bundleIdentifier: "com.apple.Music") else { return nil }

        let script = """
        tell application "Music"
            try
                set playerState to player state is playing
                set currentTrackName to name of current track
                set currentTrackArtist to artist of current track
                set currentTrackAlbum to album of current track
                set trackPosition to player position
                set trackDuration to duration of current track
                set shuffleState to shuffle enabled
                set repeatState to song repeat
                if repeatState is off then
                    set repeatValue to 1
                else if repeatState is one then
                    set repeatValue to 2
                else if repeatState is all then
                    set repeatValue to 3
                end if
                set currentVolume to sound volume
                return {playerState, currentTrackName, currentTrackArtist, currentTrackAlbum, trackPosition, trackDuration, shuffleState, repeatValue, currentVolume}
            on error
                return {false, "", "", "", 0, 0, false, 1, 50}
            end try
        end tell
        """

        guard
            let descriptor = try? await NowPlayingAppleScriptRunner.execute(script),
            descriptor.numberOfItems >= 9
        else {
            return nil
        }

        let volumePercentage = descriptor.atIndex(9)?.doubleValue ?? 50

        return NowPlayingApplicationPlaybackState(
            bundleIdentifier: "com.apple.Music",
            isPlaying: descriptor.atIndex(1)?.booleanValue ?? false,
            title: descriptor.atIndex(2)?.stringValue,
            artist: descriptor.atIndex(3)?.stringValue,
            album: descriptor.atIndex(4)?.stringValue,
            elapsedTime: descriptor.atIndex(5)?.doubleValue,
            duration: descriptor.atIndex(6)?.doubleValue,
            isShuffled: descriptor.atIndex(7)?.booleanValue,
            repeatMode: NowPlayingRepeatMode(mediaRemoteValue: Int(descriptor.atIndex(8)?.int32Value ?? 1)),
            volume: min(max(volumePercentage / 100, 0), 1),
            refreshedAt: .now
        )
    }

    func spotifyPlaybackState() async -> NowPlayingApplicationPlaybackState? {
        guard isApplicationRunning(bundleIdentifier: "com.spotify.client") else { return nil }

        let script = """
        tell application "Spotify"
            try
                set playerState to player state is playing
                set currentTrackName to name of current track
                set currentTrackArtist to artist of current track
                set currentTrackAlbum to album of current track
                set trackPosition to player position
                set trackDuration to duration of current track
                set shuffleState to shuffling
                set repeatState to repeating
                set currentVolume to sound volume
                return {playerState, currentTrackName, currentTrackArtist, currentTrackAlbum, trackPosition, trackDuration, shuffleState, repeatState, currentVolume}
            on error
                return {false, "", "", "", 0, 0, false, false, 50}
            end try
        end tell
        """

        guard
            let descriptor = try? await NowPlayingAppleScriptRunner.execute(script),
            descriptor.numberOfItems >= 9
        else {
            return nil
        }

        let durationMilliseconds = descriptor.atIndex(6)?.doubleValue ?? 0
        let volumePercentage = descriptor.atIndex(9)?.doubleValue ?? 50

        return NowPlayingApplicationPlaybackState(
            bundleIdentifier: "com.spotify.client",
            isPlaying: descriptor.atIndex(1)?.booleanValue ?? false,
            title: descriptor.atIndex(2)?.stringValue,
            artist: descriptor.atIndex(3)?.stringValue,
            album: descriptor.atIndex(4)?.stringValue,
            elapsedTime: descriptor.atIndex(5)?.doubleValue,
            duration: durationMilliseconds > 0 ? durationMilliseconds / 1_000 : nil,
            isShuffled: descriptor.atIndex(7)?.booleanValue,
            repeatMode: (descriptor.atIndex(8)?.booleanValue ?? false) ? .all : .off,
            volume: min(max(volumePercentage / 100, 0), 1),
            refreshedAt: .now
        )
    }

    func sendYouTubeMusic(_ command: NowPlayingCommand) -> Bool {
        guard isApplicationRunning(bundleIdentifier: "com.github.th-ch.youtube-music") else { return false }

        Task {
            await youtubeMusicClient.send(command)
        }

        return true
    }

    func appleMusicFavoriteState() async -> Bool? {
        guard isApplicationRunning(bundleIdentifier: "com.apple.Music") else { return nil }

        let script = """
        tell application "Music"
            try
                return favorited of current track
            on error
                try
                    return loved of current track
                on error
                    return false
                end try
            end try
        end tell
        """

        return try? await NowPlayingAppleScriptRunner.execute(script)?.booleanValue
    }

    func appleMusicCommandBody(for command: NowPlayingCommand) -> String? {
        switch command {
        case .play:
            return "play"
        case .pause:
            return "pause"
        case .togglePlayPause:
            return "playpause"
        case .nextTrack:
            return "next track"
        case .previousTrack:
            return "previous track"
        case .seek(let elapsedTime):
            return "set player position to \(max(0, elapsedTime))"
        case .setShuffle(let isEnabled):
            return "set shuffle enabled to \(appleScriptBool(isEnabled))"
        case .setRepeatMode(let repeatMode):
            return "set song repeat to \(appleMusicRepeatValue(for: repeatMode))"
        case .setVolume(let volume):
            return "set sound volume to \(volumePercentage(from: volume))"
        case .setFavorite(let isFavorite):
            return """
            try
                set favorited of current track to \(appleScriptBool(isFavorite))
            on error
                set loved of current track to \(appleScriptBool(isFavorite))
            end try
            """
        }
    }

    func spotifyCommandBody(for command: NowPlayingCommand) -> String? {
        switch command {
        case .play:
            return "play"
        case .pause:
            return "pause"
        case .togglePlayPause:
            return "playpause"
        case .nextTrack:
            return "next track"
        case .previousTrack:
            return "previous track"
        case .seek(let elapsedTime):
            return "set player position to \(max(0, elapsedTime))"
        case .setShuffle(let isEnabled):
            return "set shuffling to \(appleScriptBool(isEnabled))"
        case .setRepeatMode(let repeatMode):
            return "set repeating to \(appleScriptBool(repeatMode != .off))"
        case .setVolume(let volume):
            return "set sound volume to \(volumePercentage(from: volume))"
        case .setFavorite:
            return nil
        }
    }

    func appleMusicRepeatValue(for repeatMode: NowPlayingRepeatMode) -> String {
        switch repeatMode {
        case .off:
            return "off"
        case .one:
            return "one"
        case .all:
            return "all"
        }
    }

    func isApplicationRunning(bundleIdentifier: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }

    func appleScriptBool(_ value: Bool) -> String {
        value ? "true" : "false"
    }

    func volumePercentage(from volume: Double) -> Int {
        Int((min(max(volume, 0), 1) * 100).rounded())
    }
}

enum NowPlayingAppleScriptRunner {
    @discardableResult
    static func execute(_ scriptText: String) async throws -> NSAppleEventDescriptor? {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let script = NSAppleScript(source: scriptText)
                var error: NSDictionary?

                if let descriptor = script?.executeAndReturnError(&error) {
                    continuation.resume(returning: descriptor)
                } else if let error {
                    continuation.resume(
                        throwing: NSError(
                            domain: "DynamicNotch.AppleScriptError",
                            code: 1,
                            userInfo: error as? [String: Any]
                        )
                    )
                } else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "DynamicNotch.AppleScriptError",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Unknown AppleScript error"]
                        )
                    )
                }
            }
        }
    }

    static func executeVoid(_ scriptText: String) async throws {
        _ = try await execute(scriptText)
    }
}

private final class YouTubeMusicRemoteClient {
    private struct AuthResponse: Decodable {
        let accessToken: String
    }

    private struct LikeStateResponse: Decodable {
        let state: String?
    }

    private struct PlaybackResponse: Decodable {
        let isPaused: Bool
        let title: String?
        let artist: String?
        let album: String?
        let elapsedSeconds: Double?
        let songDuration: Double?
        let repeatMode: Int?
        let isShuffled: Bool?
        let volume: Double?
    }

    private let baseURL = URL(string: "http://localhost:26538")!
    private let session: URLSession
    private let decoder = JSONDecoder()
    private var accessToken: String?
    private var authenticationTask: Task<String, Error>?

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 10
        session = URLSession(configuration: configuration)
    }

    func send(_ command: NowPlayingCommand) async {
        do {
            switch command {
            case .play:
                _ = try await sendAPICommand(endpoint: "/play")
            case .pause:
                _ = try await sendAPICommand(endpoint: "/pause")
            case .togglePlayPause:
                _ = try await sendAPICommand(endpoint: "/toggle-play")
            case .nextTrack:
                _ = try await sendAPICommand(endpoint: "/next")
            case .previousTrack:
                _ = try await sendAPICommand(endpoint: "/previous")
            case .seek(let elapsedTime):
                _ = try await sendAPICommand(
                    endpoint: "/seek-to",
                    body: ["seconds": max(0, elapsedTime)]
                )
            case .setShuffle:
                _ = try await sendAPICommand(endpoint: "/shuffle")
            case .setRepeatMode:
                _ = try await sendAPICommand(endpoint: "/switch-repeat")
            case .setVolume(let volume):
                _ = try await sendAPICommand(
                    endpoint: "/volume",
                    body: ["volume": Int((min(max(volume, 0), 1) * 100).rounded())]
                )
            case .setFavorite(let isFavorite):
                try await setFavorite(isFavorite)
            }
        } catch YouTubeMusicRemoteError.authenticationRequired {
            invalidateToken()
        } catch {
            return
        }
    }

    func favoriteState() async -> Bool? {
        do {
            let data = try await sendAPICommand(endpoint: "/like-state", method: "GET")
            let response = try decoder.decode(LikeStateResponse.self, from: data)

            switch response.state?.uppercased() {
            case "LIKE":
                return true
            case "DISLIKE", "INDIFFERENT", "NONE":
                return false
            default:
                return false
            }
        } catch YouTubeMusicRemoteError.authenticationRequired {
            invalidateToken()
            return nil
        } catch {
            return nil
        }
    }

    func playbackState() async -> NowPlayingApplicationPlaybackState? {
        do {
            let data = try await sendAPICommand(endpoint: "/song", method: "GET")
            let response = try decoder.decode(PlaybackResponse.self, from: data)

            return NowPlayingApplicationPlaybackState(
                bundleIdentifier: "com.github.th-ch.youtube-music",
                isPlaying: !response.isPaused,
                title: response.title,
                artist: response.artist,
                album: response.album,
                elapsedTime: response.elapsedSeconds,
                duration: response.songDuration,
                isShuffled: response.isShuffled,
                repeatMode: NowPlayingRepeatMode(youtubeMusicValue: response.repeatMode),
                volume: response.volume.map { min(max($0 / 100, 0), 1) },
                refreshedAt: .now
            )
        } catch YouTubeMusicRemoteError.authenticationRequired {
            invalidateToken()
            return nil
        } catch {
            return nil
        }
    }

    private func setFavorite(_ isFavorite: Bool) async throws {
        let currentState = await favoriteState()

        guard let currentState else {
            if isFavorite {
                _ = try await sendAPICommand(endpoint: "/like")
            }
            return
        }

        guard currentState != isFavorite else { return }
        _ = try await sendAPICommand(endpoint: "/like")
    }

    private func authenticate() async throws -> String {
        if let accessToken {
            return accessToken
        }

        if let authenticationTask {
            return try await authenticationTask.value
        }

        let task = Task<String, Error> { [baseURL, session, decoder] in
            let url = baseURL
                .appendingPathComponent("auth")
                .appendingPathComponent("boringNotch")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let (data, response) = try await session.data(for: request)
            try Self.validate(response)
            return try decoder.decode(AuthResponse.self, from: data).accessToken
        }

        authenticationTask = task

        do {
            let token = try await task.value
            accessToken = token
            authenticationTask = nil
            return token
        } catch {
            authenticationTask = nil
            throw error
        }
    }

    private func sendAPICommand(
        endpoint: String,
        method: String = "POST",
        body: [String: Any]? = nil
    ) async throws -> Data {
        let token = try await authenticate()
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/")))

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        try Self.validate(response)
        return data
    }

    private func invalidateToken() {
        accessToken = nil
        authenticationTask?.cancel()
        authenticationTask = nil
    }

    private static func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YouTubeMusicRemoteError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw YouTubeMusicRemoteError.authenticationRequired
        default:
            throw YouTubeMusicRemoteError.httpError(httpResponse.statusCode)
        }
    }
}

private enum YouTubeMusicRemoteError: Error {
    case invalidResponse
    case authenticationRequired
    case httpError(Int)
}
