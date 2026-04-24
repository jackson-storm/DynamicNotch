import Foundation

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
            lhs.contentItemIdentifier == rhs.contentItemIdentifier
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
