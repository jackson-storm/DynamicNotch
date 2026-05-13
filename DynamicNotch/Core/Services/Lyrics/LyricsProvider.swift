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

struct TrackLyrics: Equatable, Sendable {
    let trackKey: String
    let lines: [LyricLine]
    let isSynced: Bool

    func activeLineIndex(at elapsedTime: TimeInterval) -> Int? {
        guard isSynced, lines.isEmpty == false else { return nil }

        let playbackPosition = elapsedTime + 0.18
        return lines.lastIndex { line in
            guard let startTime = line.startTime else { return false }
            return startTime <= playbackPosition
        } ?? 0
    }
}

struct LyricLine: Identifiable, Equatable, Sendable {
    let id: Int
    let startTime: TimeInterval?
    let text: String
}

@MainActor
protocol LyricsProviding: AnyObject {
    func lyrics(for snapshot: NowPlayingSnapshot) async throws -> TrackLyrics?
}

@MainActor
final class InactiveLyricsProvider: LyricsProviding {
    func lyrics(for snapshot: NowPlayingSnapshot) async throws -> TrackLyrics? {
        nil
    }
}

@MainActor
final class LRCLIBLyricsProvider: LyricsProviding {
    private enum CacheEntry {
        case found(TrackLyrics)
        case missing

        var lyrics: TrackLyrics? {
            switch self {
            case .found(let lyrics):
                return lyrics
            case .missing:
                return nil
            }
        }
    }

    private struct Response: Decodable {
        let id: Int?
        let trackName: String?
        let artistName: String?
        let albumName: String?
        let duration: Double?
        let instrumental: Bool?
        let plainLyrics: String?
        let syncedLyrics: String?
    }

    private static let baseURL = URL(string: "https://lrclib.net/api")!

    private let session: URLSession
    private let decoder = JSONDecoder()
    private var cache: [String: CacheEntry] = [:]

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 8
        session = URLSession(configuration: configuration)
    }

    func lyrics(for snapshot: NowPlayingSnapshot) async throws -> TrackLyrics? {
        guard let trackKey = snapshot.lyricsLookupKey else { return nil }

        if let cached = cache[trackKey] {
            return cached.lyrics
        }

        if let exactLyrics = try await fetchExactLyrics(for: snapshot, trackKey: trackKey) {
            cache[trackKey] = .found(exactLyrics)
            return exactLyrics
        }

        let searchedLyrics = try await searchLyrics(for: snapshot, trackKey: trackKey)
        cache[trackKey] = searchedLyrics.map(CacheEntry.found) ?? .missing
        return searchedLyrics
    }

    private func fetchExactLyrics(
        for snapshot: NowPlayingSnapshot,
        trackKey: String
    ) async throws -> TrackLyrics? {
        guard let url = makeURL(
            endpoint: "get",
            queryItems: queryItems(for: snapshot, includeAlbum: true, includeDuration: true)
        ) else {
            return nil
        }

        let data = try await data(from: url, allowsNotFound: true)
        guard let data else { return nil }

        let response = try decoder.decode(Response.self, from: data)
        return makeTrackLyrics(from: response, trackKey: trackKey)
    }

    private func searchLyrics(
        for snapshot: NowPlayingSnapshot,
        trackKey: String
    ) async throws -> TrackLyrics? {
        let searchAttempts = [
            queryItems(for: snapshot, includeAlbum: false, includeDuration: true),
            queryItems(for: snapshot, includeAlbum: false, includeDuration: false),
            [
                URLQueryItem(
                    name: "q",
                    value: [snapshot.artist.trimmed, snapshot.title.trimmed]
                        .filter { $0.isEmpty == false }
                        .joined(separator: " ")
                )
            ]
        ]

        for queryItems in searchAttempts {
            guard let url = makeURL(endpoint: "search", queryItems: queryItems) else {
                continue
            }

            guard let data = try await data(from: url, allowsNotFound: false) else {
                continue
            }

            let responses = try decoder.decode([Response].self, from: data)
            if let lyrics = bestResponse(from: responses, for: snapshot)
                .flatMap({ makeTrackLyrics(from: $0, trackKey: trackKey) }) {
                return lyrics
            }
        }

        return nil
    }

    private func makeURL(
        endpoint: String,
        queryItems: [URLQueryItem]
    ) -> URL? {
        var components = URLComponents(
            url: Self.baseURL.appendingPathComponent(endpoint),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems
        return components?.url
    }

    private func queryItems(
        for snapshot: NowPlayingSnapshot,
        includeAlbum: Bool,
        includeDuration: Bool
    ) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "track_name", value: snapshot.title.trimmed),
            URLQueryItem(name: "artist_name", value: snapshot.artist.trimmed)
        ]

        if includeAlbum, snapshot.album.trimmed.isEmpty == false {
            items.append(URLQueryItem(name: "album_name", value: snapshot.album.trimmed))
        }

        if includeDuration, snapshot.duration > 0 {
            items.append(URLQueryItem(name: "duration", value: "\(Int(snapshot.duration.rounded()))"))
        }

        return items
    }

    private func data(from url: URL, allowsNotFound: Bool) async throws -> Data? {
        var request = URLRequest(url: url)
        request.setValue(
            "DynamicNotch/1.0 (https://github.com/jackson-storm/DynamicNotch)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 404 where allowsNotFound:
            return nil
        default:
            throw URLError(.badServerResponse)
        }
    }

    private func bestResponse(
        from responses: [Response],
        for snapshot: NowPlayingSnapshot
    ) -> Response? {
        responses
            .filter { response in
                response.instrumental == true ||
                response.syncedLyrics?.trimmed.isEmpty == false ||
                response.plainLyrics?.trimmed.isEmpty == false
            }
            .max { first, second in
                matchScore(first, snapshot: snapshot) < matchScore(second, snapshot: snapshot)
            }
    }

    private func matchScore(_ response: Response, snapshot: NowPlayingSnapshot) -> Int {
        let title = snapshot.title.normalizedLyricsSearchText
        let artist = snapshot.artist.normalizedLyricsSearchText
        let album = snapshot.album.normalizedLyricsSearchText
        let responseTitle = response.trackName?.normalizedLyricsSearchText ?? ""
        let responseArtist = response.artistName?.normalizedLyricsSearchText ?? ""
        let responseAlbum = response.albumName?.normalizedLyricsSearchText ?? ""
        let durationDelta = response.duration.map {
            abs(Int($0.rounded()) - Int(snapshot.duration.rounded()))
        }

        var score = 0
        if responseTitle == title { score += 120 }
        if responseArtist == artist { score += 90 }
        if album.isEmpty == false, responseAlbum == album { score += 35 }
        if response.syncedLyrics?.trimmed.isEmpty == false { score += 20 }
        if let durationDelta {
            if durationDelta <= 2 { score += 24 }
            else if durationDelta <= 6 { score += 12 }
        }

        return score
    }

    private func makeTrackLyrics(
        from response: Response,
        trackKey: String
    ) -> TrackLyrics? {
        if response.instrumental == true {
            return TrackLyrics(
                trackKey: trackKey,
                lines: [LyricLine(id: 0, startTime: nil, text: "Instrumental")],
                isSynced: false
            )
        }

        let syncedLines = Self.parseSyncedLyrics(response.syncedLyrics)
        if syncedLines.isEmpty == false {
            return TrackLyrics(trackKey: trackKey, lines: syncedLines, isSynced: true)
        }

        let plainLines = Self.parsePlainLyrics(response.plainLyrics)
        if plainLines.isEmpty == false {
            return TrackLyrics(trackKey: trackKey, lines: plainLines, isSynced: false)
        }

        return nil
    }

    private static func parsePlainLyrics(_ lyrics: String?) -> [LyricLine] {
        lyrics?
            .components(separatedBy: .newlines)
            .map(\.trimmed)
            .filter { $0.isEmpty == false }
            .enumerated()
            .map { index, text in
                LyricLine(id: index, startTime: nil, text: text)
            } ?? []
    }

    private static func parseSyncedLyrics(_ lyrics: String?) -> [LyricLine] {
        guard let lyrics, lyrics.trimmed.isEmpty == false else { return [] }

        let pattern = #"\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        var parsedLines: [(startTime: TimeInterval, text: String)] = []

        for rawLine in lyrics.components(separatedBy: .newlines) {
            let nsLine = rawLine as NSString
            let fullRange = NSRange(location: 0, length: nsLine.length)
            let matches = expression.matches(in: rawLine, range: fullRange)
            guard let lastMatch = matches.last else { continue }

            let textStart = lastMatch.range.location + lastMatch.range.length
            let text = nsLine.substring(from: min(textStart, nsLine.length)).trimmed
            guard text.isEmpty == false else { continue }

            for match in matches {
                guard let startTime = startTime(from: match, line: nsLine) else { continue }
                parsedLines.append((startTime: startTime, text: text))
            }
        }

        return parsedLines
            .sorted { $0.startTime < $1.startTime }
            .enumerated()
            .map { index, line in
                LyricLine(id: index, startTime: line.startTime, text: line.text)
            }
    }

    private static func startTime(
        from match: NSTextCheckingResult,
        line: NSString
    ) -> TimeInterval? {
        guard
            let minutes = integerValue(in: match.range(at: 1), line: line),
            let seconds = integerValue(in: match.range(at: 2), line: line)
        else {
            return nil
        }

        let fraction = fractionalSeconds(in: match.range(at: 3), line: line)
        return TimeInterval((minutes * 60) + seconds) + fraction
    }

    private static func integerValue(in range: NSRange, line: NSString) -> Int? {
        guard range.location != NSNotFound else { return nil }
        return Int(line.substring(with: range))
    }

    private static func fractionalSeconds(in range: NSRange, line: NSString) -> TimeInterval {
        guard range.location != NSNotFound else { return 0 }

        let rawValue = line.substring(with: range)
        guard let value = Double(rawValue) else { return 0 }

        switch rawValue.count {
        case 1:
            return value / 10
        case 2:
            return value / 100
        default:
            return value / 1000
        }
    }
}

extension NowPlayingSnapshot {
    var lyricsLookupKey: String? {
        let title = title.trimmed
        let artist = artist.trimmed

        guard title.isEmpty == false, artist.isEmpty == false else {
            return nil
        }

        return [
            title.normalizedLyricsSearchText,
            artist.normalizedLyricsSearchText,
            album.normalizedLyricsSearchText,
            "\(Int(duration.rounded()))"
        ].joined(separator: "|")
    }
}

private extension String {
    var normalizedLyricsSearchText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "’", with: "'")
    }
}
