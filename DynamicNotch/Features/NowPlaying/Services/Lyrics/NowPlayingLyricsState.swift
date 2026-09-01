//
//  NowPlayingLyricsState.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/13/26.
//

import Foundation

enum NowPlayingLyricsState: Equatable, Sendable {
    case idle
    case loading(trackKey: String)
    case loaded(TrackLyrics)
    case notFound(trackKey: String)
    case failed(trackKey: String)

    var trackKey: String? {
        switch self {
        case .idle:
            return nil
        case .loading(let trackKey),
             .notFound(let trackKey),
             .failed(let trackKey):
            return trackKey
        case .loaded(let lyrics):
            return lyrics.trackKey
        }
    }
}
