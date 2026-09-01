//
//  InactiveLyricsProvider.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/13/26.
//

import Foundation

@MainActor
final class InactiveLyricsProvider: LyricsProviding {
    func lyrics(for snapshot: NowPlayingSnapshot) async throws -> TrackLyrics? {
        nil
    }
}
