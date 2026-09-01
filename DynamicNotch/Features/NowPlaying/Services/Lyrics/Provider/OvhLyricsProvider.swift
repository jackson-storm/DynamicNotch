//
//  OvhLyricsProvider.swift
//  DynamicNotch
//

import Foundation

@MainActor
final class OvhLyricsProvider: LyricsProviding {
    private struct Response: Decodable {
        let lyrics: String
    }

    private let session: URLSession
    private let decoder = JSONDecoder()
    private var cache: [String: TrackLyrics] = [:]

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 45
        session = URLSession(configuration: configuration)
    }

    func lyrics(for snapshot: NowPlayingSnapshot) async throws -> TrackLyrics? {
        guard let trackKey = snapshot.lyricsLookupKey else { return nil }

        if let cached = cache[trackKey] {
            return cached
        }

        guard let url = makeURL(for: snapshot) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("DynamicNotch/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        guard let apiResponse = try? decoder.decode(Response.self, from: data) else {
            return nil
        }
        
        let lyrics = makeTrackLyrics(from: apiResponse.lyrics, trackKey: trackKey)
        if let lyrics {
            cache[trackKey] = lyrics
        }
        return lyrics
    }

    private func makeURL(for snapshot: NowPlayingSnapshot) -> URL? {
        let artist = snapshot.artist.trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let title = snapshot.title.trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        
        guard !artist.isEmpty, !title.isEmpty else { return nil }
        return URL(string: "https://api.lyrics.ovh/v1/\(artist)/\(title)")
    }

    private func makeTrackLyrics(from lyricsString: String, trackKey: String) -> TrackLyrics? {
        let trimmed = lyricsString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        // Some Lyrics.ovh results include "Paroles de la chanson" at the start, but we can just use the lines directly.
        let lines = trimmed
            .components(separatedBy: .newlines)
            .map(\.trimmed)
            .filter { $0.isEmpty == false }
            .enumerated()
            .map { index, text in
                LyricLine(id: index, startTime: nil, text: text)
            }
        
        guard lines.isEmpty == false else { return nil }
        
        return TrackLyrics(trackKey: trackKey, lines: lines, isSynced: false)
    }
}
