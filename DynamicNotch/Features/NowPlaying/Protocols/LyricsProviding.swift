//
//  LyricsProviding.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/13/26.
//

@MainActor
protocol LyricsProviding: AnyObject {
    func lyrics(for snapshot: NowPlayingSnapshot) async throws -> TrackLyrics?
}
