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
        var primaryError: Error?

        for (index, provider) in providers.enumerated() {
            do {
                if let lyrics = try await provider.lyrics(for: snapshot) {
                    return lyrics
                }
            } catch {
                try Task.checkCancellation()
                // Only the primary provider's failure is worth retrying; fallbacks are best effort.
                if index == 0 {
                    primaryError = error
                }
            }
        }

        if let primaryError {
            throw primaryError
        }
        return nil
    }

    func invalidateCache(for snapshot: NowPlayingSnapshot) {
        providers.forEach { $0.invalidateCache(for: snapshot) }
    }
}
