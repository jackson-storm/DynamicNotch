import SwiftUI

enum NowPlayingProgressTintStyle: String, CaseIterable {
    case `default`
    case artwork
    case systemAccent

    var title: LocalizedStringKey {
        switch self {
        case .`default`:
            return "settings.nowPlaying.progressTintStyle.plainWhite"
        case .artwork:
            return "settings.nowPlaying.progressTintStyle.artworkColor"
        case .systemAccent:
            return "settings.nowPlaying.progressTintStyle.accentColor"
        }
    }

    static func resolved(_ rawValue: String?) -> Self {
        rawValue.flatMap(Self.init(rawValue:)) ?? .`default`
    }
}
