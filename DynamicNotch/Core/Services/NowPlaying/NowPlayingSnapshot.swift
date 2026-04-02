import Foundation

struct NowPlayingSnapshot: Equatable {
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let elapsedTime: TimeInterval
    let playbackRate: Double
    let artworkData: Data?
    let refreshedAt: Date

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
        lhs.artworkData == rhs.artworkData
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
