import XCTest
import SwiftUI
@testable import DynamicNotch

@MainActor
final class NowPlayingLyricsTests: XCTestCase {
    // MARK: - Lookup retry

    func testFailedLookupIsRetriedUntilItSucceeds() async {
        let provider = FakeLyricsProvider(results: [
            .failure(URLError(.timedOut)),
            .failure(URLError(.badServerResponse)),
            .success(makeTrackLyrics())
        ])
        let (viewModel, service) = makeViewModel(provider: provider)
        service.publish(makeNowPlayingSnapshot())

        viewModel.setLyricsPresentationActive(true, source: "test")

        await assertEventually {
            await MainActor.run { viewModel.lyricsState.isLoaded }
        }
        XCTAssertEqual(provider.lookupCount, 3)
    }

    func testLookupIsMarkedFailedAfterRetriesRunOut() async {
        let provider = FakeLyricsProvider(results: Array(repeating: .failure(URLError(.timedOut)), count: 4))
        let (viewModel, service) = makeViewModel(provider: provider)
        service.publish(makeNowPlayingSnapshot())

        viewModel.setLyricsPresentationActive(true, source: "test")

        await assertEventually {
            await MainActor.run {
                if case .failed = viewModel.lyricsState { return true }
                return false
            }
        }
        XCTAssertEqual(provider.lookupCount, 4)
    }

    func testMissingLyricsAreNotRetried() async {
        let provider = FakeLyricsProvider(results: [.success(nil)])
        let (viewModel, service) = makeViewModel(provider: provider)
        service.publish(makeNowPlayingSnapshot())

        viewModel.setLyricsPresentationActive(true, source: "test")

        await assertEventually {
            await MainActor.run {
                if case .notFound = viewModel.lyricsState { return true }
                return false
            }
        }
        XCTAssertEqual(provider.lookupCount, 1)
    }

    func testCancelledLookupDoesNotStayLoading() {
        let provider = FakeLyricsProvider(results: [.success(makeTrackLyrics())], delay: 5)
        let (viewModel, service) = makeViewModel(provider: provider)
        service.publish(makeNowPlayingSnapshot())

        viewModel.setLyricsPresentationActive(true, source: "test")
        XCTAssertTrue(viewModel.lyricsState.isLoading)

        viewModel.setLyricsPresentationActive(false, source: "test")

        XCTAssertEqual(viewModel.lyricsState, .idle)
    }

    func testReloadLyricsInvalidatesCacheAndLooksUpAgain() async {
        let provider = FakeLyricsProvider(results: [.success(nil), .success(makeTrackLyrics())])
        let (viewModel, service) = makeViewModel(provider: provider)
        service.publish(makeNowPlayingSnapshot())
        viewModel.setLyricsPresentationActive(true, source: "test")

        await assertEventually {
            await MainActor.run {
                if case .notFound = viewModel.lyricsState { return true }
                return false
            }
        }

        viewModel.reloadLyrics()

        await assertEventually {
            await MainActor.run { viewModel.lyricsState.isLoaded }
        }
        XCTAssertEqual(provider.invalidatedKeys.count, 1)
        XCTAssertEqual(provider.lookupCount, 2)
    }

    // MARK: - Presentation sources

    func testLyricsStayActiveWhileAnySourceIsActive() async {
        let provider = FakeLyricsProvider(results: [.success(makeTrackLyrics())], delay: 5)
        let (viewModel, service) = makeViewModel(provider: provider)
        service.publish(makeNowPlayingSnapshot())

        viewModel.setLyricsPresentationActive(true, source: "notch")
        viewModel.setLyricsPresentationActive(true, source: "floating")
        viewModel.setLyricsPresentationActive(false, source: "notch")

        XCTAssertTrue(viewModel.lyricsState.isLoading)
        await assertEventually {
            await MainActor.run { provider.lookupCount == 1 }
        }

        viewModel.setLyricsPresentationActive(false, source: "floating")

        XCTAssertEqual(viewModel.lyricsState, .idle)
    }

    // MARK: - Delay

    func testPlaybackTimeSubtractsGlobalAndSongDelay() {
        let defaults = makeDefaults()
        defaults.set(1.0, forKey: GeneralSettingsStorage.Keys.lyricsGlobalDelay)
        let (viewModel, service) = makeViewModel(defaults: defaults)
        let snapshot = makeNowPlayingSnapshot(elapsedTime: 30, playbackRate: 0)
        service.publish(snapshot)

        viewModel.adjustLyricsTrackDelay(by: 0.5)

        XCTAssertEqual(viewModel.lyricsTrackDelay, 0.5, accuracy: 0.0001)
        XCTAssertEqual(viewModel.lyricsTotalDelay, 1.5, accuracy: 0.0001)
        XCTAssertEqual(viewModel.lyricsPlaybackTime(at: snapshot.refreshedAt), 28.5, accuracy: 0.0001)
    }

    func testSongDelayIsRememberedPerTrack() {
        let defaults = makeDefaults()
        let (viewModel, service) = makeViewModel(defaults: defaults)
        let firstTrack = makeNowPlayingSnapshot(title: "First")
        let secondTrack = makeNowPlayingSnapshot(title: "Second")

        service.publish(firstTrack)
        viewModel.adjustLyricsTrackDelay(by: -0.5)
        viewModel.adjustLyricsTrackDelay(by: -0.5)
        XCTAssertEqual(viewModel.lyricsTrackDelay, -1, accuracy: 0.0001)

        service.publish(secondTrack)
        XCTAssertEqual(viewModel.lyricsTrackDelay, 0)

        service.publish(firstTrack)
        XCTAssertEqual(viewModel.lyricsTrackDelay, -1, accuracy: 0.0001)

        viewModel.resetLyricsTrackDelay()
        XCTAssertEqual(viewModel.lyricsTrackDelay, 0)
        XCTAssertEqual(
            (defaults.dictionary(forKey: NowPlayingViewModel.lyricsTrackDelaysStorageKey) ?? [:]).count,
            0
        )
    }

    func testDelayChangesBumpChangeCount() {
        let (viewModel, service) = makeViewModel()
        service.publish(makeNowPlayingSnapshot())

        viewModel.adjustLyricsTrackDelay(by: 0.5)
        viewModel.noteLyricsGlobalDelayChanged()

        XCTAssertEqual(viewModel.lyricsDelayChangeCount, 2)
    }

    // MARK: - Helpers

    private func makeViewModel(
        provider: FakeLyricsProvider? = nil,
        defaults: UserDefaults? = nil
    ) -> (NowPlayingViewModel, FakeNowPlayingService) {
        let service = FakeNowPlayingService()
        let viewModel = NowPlayingViewModel(
            service: service,
            lyricsProvider: provider ?? FakeLyricsProvider(results: []),
            favoritesStore: defaults ?? makeDefaults()
        )
        viewModel.lyricsRetryDelays = [0.01, 0.01, 0.01]
        TestLifetime.retain(viewModel)
        viewModel.startMonitoring()
        return (viewModel, service)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NowPlayingLyricsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

@MainActor
final class CompositeLyricsProviderTests: XCTestCase {
    func testFallsBackWhenPrimaryFails() async throws {
        let lyrics = makeTrackLyrics()
        let provider = CompositeLyricsProvider(providers: [
            FakeLyricsProvider(results: [.failure(URLError(.timedOut))]),
            FakeLyricsProvider(results: [.success(lyrics)])
        ])

        let result = try await provider.lyrics(for: makeNowPlayingSnapshot())

        XCTAssertEqual(result?.lines, lyrics.lines)
    }

    func testRethrowsPrimaryFailureWhenFallbackFindsNothing() async {
        let provider = CompositeLyricsProvider(providers: [
            FakeLyricsProvider(results: [.failure(URLError(.timedOut))]),
            FakeLyricsProvider(results: [.success(nil)])
        ])

        do {
            _ = try await provider.lyrics(for: makeNowPlayingSnapshot())
            XCTFail("Expected the primary provider's error to be rethrown so the lookup can be retried.")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .timedOut)
        }
    }

    func testReturnsNilWhenPrimaryFindsNothingAndFallbackFails() async throws {
        let provider = CompositeLyricsProvider(providers: [
            FakeLyricsProvider(results: [.success(nil)]),
            FakeLyricsProvider(results: [.failure(URLError(.badServerResponse))])
        ])

        let result = try await provider.lyrics(for: makeNowPlayingSnapshot())

        XCTAssertNil(result)
    }

    func testInvalidateCacheReachesEveryProvider() {
        let primary = FakeLyricsProvider(results: [])
        let fallback = FakeLyricsProvider(results: [])
        let provider = CompositeLyricsProvider(providers: [primary, fallback])

        provider.invalidateCache(for: makeNowPlayingSnapshot())

        XCTAssertEqual(primary.invalidatedKeys.count, 1)
        XCTAssertEqual(fallback.invalidatedKeys.count, 1)
    }
}

final class LyricsLanguageDetectorTests: XCTestCase {
    func testDetectsDominantLanguage() {
        let lyrics = makeTrackLyrics(lines: [
            "We walked along the river at night",
            "Every light in the city was shining",
            "And I remembered how it used to feel"
        ])

        XCTAssertEqual(LyricsLanguageDetector.dominantLanguage(in: lyrics)?.languageCode, "en")
    }

    func testReturnsNilForUndeterminedText() {
        let lyrics = makeTrackLyrics(lines: ["♪", "…"])

        XCTAssertNil(LyricsLanguageDetector.dominantLanguage(in: lyrics))
    }

    func testSameLanguageIgnoresRegionButNotScript() {
        XCTAssertTrue(LyricsLanguageDetector.isSameLanguage(
            Locale.Language(identifier: "en"),
            Locale.Language(identifier: "en-US")
        ))
        XCTAssertFalse(LyricsLanguageDetector.isSameLanguage(
            Locale.Language(identifier: "zh-Hans"),
            Locale.Language(identifier: "zh-Hant")
        ))
        XCTAssertFalse(LyricsLanguageDetector.isSameLanguage(
            Locale.Language(identifier: "ko"),
            Locale.Language(identifier: "id")
        ))
    }
}

final class FloatingLyricsAppearanceTests: XCTestCase {
    func testPanelHeightGrowsWithVisibleRows() {
        let minimal = makeAppearance(showsTrackInfo: false, showsNextLine: false, isTranslationEnabled: false)
        let withNextLine = makeAppearance(showsTrackInfo: false, showsNextLine: true, isTranslationEnabled: false)
        let withTranslation = makeAppearance(showsTrackInfo: false, showsNextLine: true, isTranslationEnabled: true)
        let full = makeAppearance(showsTrackInfo: true, showsNextLine: true, isTranslationEnabled: true)

        XCTAssertLessThan(minimal.panelHeight, withNextLine.panelHeight)
        XCTAssertLessThan(withNextLine.panelHeight, withTranslation.panelHeight)
        XCTAssertLessThan(withTranslation.panelHeight, full.panelHeight)
    }

    func testPanelHeightScalesWithFontSize() {
        XCTAssertLessThan(
            makeAppearance(fontSize: 14).panelHeight,
            makeAppearance(fontSize: 24).panelHeight
        )
        XCTAssertEqual(makeAppearance(width: 420).panelSize.width, 420)
    }

    func testHexColorRoundTrip() {
        let color = Color(lyricsHex: "#FFD166")

        XCTAssertNotNil(color)
        XCTAssertEqual(color?.lyricsHex, "#FFD166")
        XCTAssertNil(Color(lyricsHex: "not a color"))
    }

    private func makeAppearance(
        showsTrackInfo: Bool = true,
        showsNextLine: Bool = true,
        isTranslationEnabled: Bool = false,
        fontSize: CGFloat = 17,
        width: CGFloat = 340
    ) -> FloatingLyricsAppearance {
        FloatingLyricsAppearance(
            showsTrackInfo: showsTrackInfo,
            showsNextLine: showsNextLine,
            fontSize: fontSize,
            width: width,
            backgroundOpacity: 0.82,
            alignment: .leading,
            colorStyle: .white,
            customColorHex: "#FFD166",
            fontDesign: .standard,
            showsShadow: true,
            isTranslationEnabled: isTranslationEnabled,
            translationLanguage: .english
        )
    }
}

@MainActor
final class LyricsSettingsStoreTests: XCTestCase {
    func testDefaultsAndReset() {
        let suiteName = "LyricsSettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        let settings = MediaAndFilesSettingsStore(defaults: defaults)

        XCTAssertTrue(settings.isNowPlayingNotchLyricsEnabled)
        XCTAssertTrue(settings.isNowPlayingFloatingLyricsEnabled)
        XCTAssertFalse(settings.isLyricsTranslationEnabled)
        XCTAssertEqual(settings.lyricsGlobalDelay, 0)
        XCTAssertEqual(settings.floatingLyricsAppearance.panelSize.width, 340)

        settings.floatingLyricsFontSize = 26
        settings.floatingLyricsColorStyle = .custom
        settings.isFloatingLyricsPositionLocked = true
        settings.isLyricsTranslationEnabled = true
        settings.lyricsGlobalDelay = 1.5

        settings.resetFloatingLyrics()

        XCTAssertEqual(settings.floatingLyricsFontSize, 17)
        XCTAssertEqual(settings.floatingLyricsColorStyle, .white)
        XCTAssertFalse(settings.isFloatingLyricsPositionLocked)
        XCTAssertFalse(settings.isLyricsTranslationEnabled)
        XCTAssertEqual(settings.lyricsGlobalDelay, 0)
    }
}

// MARK: - Test doubles

@MainActor
final class FakeLyricsProvider: LyricsProviding {
    private var results: [Result<TrackLyrics?, Error>]
    private let delay: TimeInterval
    private(set) var lookupCount = 0
    private(set) var invalidatedKeys: [String] = []

    init(results: [Result<TrackLyrics?, Error>], delay: TimeInterval = 0) {
        self.results = results
        self.delay = delay
    }

    func lyrics(for snapshot: NowPlayingSnapshot) async throws -> TrackLyrics? {
        lookupCount += 1

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        guard !results.isEmpty else { return nil }
        let result = results.removeFirst()
        return try result.get().map { lyrics in
            TrackLyrics(trackKey: snapshot.lyricsLookupKey ?? lyrics.trackKey, lines: lyrics.lines, isSynced: lyrics.isSynced)
        }
    }

    func invalidateCache(for snapshot: NowPlayingSnapshot) {
        invalidatedKeys.append(snapshot.lyricsLookupKey ?? "")
    }
}

func makeTrackLyrics(
    lines: [String] = ["First line", "Second line", "Third line"],
    isSynced: Bool = true
) -> TrackLyrics {
    TrackLyrics(
        trackKey: "test-track",
        lines: lines.enumerated().map { index, text in
            LyricLine(id: index, startTime: isSynced ? TimeInterval(index * 5) : nil, text: text)
        },
        isSynced: isSynced
    )
}

private extension NowPlayingLyricsState {
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
