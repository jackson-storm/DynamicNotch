import Foundation

enum NowPlayingRepeatMode: Int, CaseIterable, Equatable {
    case off = 1
    case one = 2
    case all = 3

    init(mediaRemoteValue: Int?) {
        switch mediaRemoteValue {
        case Self.one.rawValue:
            self = .one
        case Self.all.rawValue:
            self = .all
        default:
            self = .off
        }
    }

    init(youtubeMusicValue: Int?) {
        switch youtubeMusicValue {
        case 1:
            self = .all
        case 2:
            self = .one
        default:
            self = .off
        }
    }

    var next: NowPlayingRepeatMode {
        switch self {
        case .off:
            return .all
        case .all:
            return .one
        case .one:
            return .off
        }
    }
}

struct NowPlayingPlaybackSource: Equatable {
    let bundleIdentifier: String?
    let parentBundleIdentifier: String?
    let processIdentifier: Int?

    var validProcessIdentifier: Int? {
        guard let processIdentifier, processIdentifier > 0 else { return nil }
        return processIdentifier
    }

    var preferredBundleIdentifier: String? {
        [
            parentBundleIdentifier?.trimmed,
            bundleIdentifier?.trimmed
        ]
            .compactMap { $0 }
            .first { !$0.isEmpty }
    }

    var hasOpenableTarget: Bool {
        preferredBundleIdentifier != nil || validProcessIdentifier != nil
    }

    var supportsFavoriteCommand: Bool {
        switch preferredBundleIdentifier {
        case "com.apple.Music", "com.github.th-ch.youtube-music":
            return true
        default:
            return false
        }
    }

    var supportsVolumeCommand: Bool {
        switch preferredBundleIdentifier {
        case "com.apple.Music", "com.spotify.client", "com.github.th-ch.youtube-music":
            return true
        default:
            return false
        }
    }
}

struct NowPlayingSnapshot: Equatable {
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let elapsedTime: TimeInterval
    let playbackRate: Double
    let artworkData: Data?
    let playbackSource: NowPlayingPlaybackSource?
    let mediaType: String?
    let contentItemIdentifier: String?
    let isShuffled: Bool
    let repeatMode: NowPlayingRepeatMode
    let volume: Double?
    let isFavorite: Bool?
    let supportsFavorite: Bool
    let supportsVolumeControl: Bool
    let refreshedAt: Date

    init(
        title: String,
        artist: String,
        album: String,
        duration: TimeInterval,
        elapsedTime: TimeInterval,
        playbackRate: Double,
        artworkData: Data?,
        playbackSource: NowPlayingPlaybackSource? = nil,
        mediaType: String? = nil,
        contentItemIdentifier: String? = nil,
        isShuffled: Bool = false,
        repeatMode: NowPlayingRepeatMode = .off,
        volume: Double? = nil,
        isFavorite: Bool? = nil,
        supportsFavorite: Bool? = nil,
        supportsVolumeControl: Bool? = nil,
        refreshedAt: Date
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.elapsedTime = elapsedTime
        self.playbackRate = playbackRate
        self.artworkData = artworkData
        self.playbackSource = playbackSource
        self.mediaType = mediaType
        self.contentItemIdentifier = contentItemIdentifier
        self.isShuffled = isShuffled
        self.repeatMode = repeatMode
        self.volume = volume
        self.isFavorite = isFavorite
        self.supportsFavorite = supportsFavorite ?? playbackSource?.supportsFavoriteCommand ?? false
        self.supportsVolumeControl = supportsVolumeControl ?? playbackSource?.supportsVolumeCommand ?? false
        self.refreshedAt = refreshedAt
    }

    var isPlaying: Bool {
        playbackRate > 0.001
    }

    var hasVisibleMetadata: Bool {
        !title.trimmed.isEmpty ||
        !artist.trimmed.isEmpty ||
        !album.trimmed.isEmpty ||
        artworkData?.isEmpty == false ||
        duration > 0
    }

    func elapsedTime(at date: Date) -> TimeInterval {
        let baseElapsed = max(0, elapsedTime)

        guard isPlaying else {
            if duration > 0 {
                return min(baseElapsed, duration)
            }
            return baseElapsed
        }

        let advancedElapsed = baseElapsed + (date.timeIntervalSince(refreshedAt) * playbackRate)

        if duration > 0 {
            return min(max(0, advancedElapsed), duration)
        }

        return max(0, advancedElapsed)
    }

    static func == (lhs: NowPlayingSnapshot, rhs: NowPlayingSnapshot) -> Bool {
        lhs.title == rhs.title &&
        lhs.artist == rhs.artist &&
        lhs.album == rhs.album &&
            lhs.duration == rhs.duration &&
            lhs.elapsedTime == rhs.elapsedTime &&
            lhs.playbackRate == rhs.playbackRate &&
            lhs.artworkData == rhs.artworkData &&
            lhs.playbackSource == rhs.playbackSource &&
            lhs.mediaType == rhs.mediaType &&
            lhs.contentItemIdentifier == rhs.contentItemIdentifier &&
            lhs.isShuffled == rhs.isShuffled &&
            lhs.repeatMode == rhs.repeatMode &&
            lhs.volume == rhs.volume &&
            lhs.isFavorite == rhs.isFavorite &&
            lhs.supportsFavorite == rhs.supportsFavorite &&
            lhs.supportsVolumeControl == rhs.supportsVolumeControl
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
