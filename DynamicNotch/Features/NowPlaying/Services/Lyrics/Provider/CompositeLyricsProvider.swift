//
//  CompositeLyricsProvider.swift
//  DynamicNotch
//

import Foundation

@MainActor
final class CompositeLyricsProvider: LyricsProviding {
    private let providers: [any LyricsProviding]

    init(providers: [any LyricsProviding]) {
        self.providers = providers
    }

    func lyrics(for snapshot: NowPlayingSnapshot) async throws -> TrackLyrics? {
        for provider in providers {
            if let lyrics = try? await provider.lyrics(for: snapshot) {
                return lyrics
            }
        }
        return nil
    }
}
