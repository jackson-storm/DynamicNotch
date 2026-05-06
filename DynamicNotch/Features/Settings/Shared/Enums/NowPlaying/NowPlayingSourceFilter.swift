import SwiftUI

enum NowPlayingSourceFilter: String, CaseIterable {
    case any
    case appleMusic
    case spotify
    case youtubeMusic

    var title: LocalizedStringKey {
        switch self {
        case .any:
            return "Any source"
        case .appleMusic:
            return "Apple Music"
        case .spotify:
            return "Spotify"
        case .youtubeMusic:
            return "YouTube Music"
        }
    }

    func allows(_ source: NowPlayingPlaybackSource?) -> Bool {
        switch self {
        case .any:
            return true
        case .appleMusic, .spotify, .youtubeMusic:
            return sourceBundleIdentifiers(from: source).contains { bundleIdentifiers.contains($0) }
        }
    }

    static func resolved(_ rawValue: String?) -> Self {
        rawValue.flatMap(Self.init(rawValue:)) ?? .any
    }

    private var bundleIdentifiers: Set<String> {
        switch self {
        case .any:
            return []
        case .appleMusic:
            return ["com.apple.Music", "com.apple.iTunes"]
        case .spotify:
            return ["com.spotify.client"]
        case .youtubeMusic:
            return ["com.github.th-ch.youtube-music"]
        }
    }

    private func sourceBundleIdentifiers(from source: NowPlayingPlaybackSource?) -> [String] {
        [
            source?.parentBundleIdentifier?.trimmed,
            source?.bundleIdentifier?.trimmed
        ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
    }
}
