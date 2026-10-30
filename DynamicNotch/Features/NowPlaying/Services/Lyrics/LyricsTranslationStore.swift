import Combine
import NaturalLanguage
import SwiftUI
@_weakLinked import Translation

/// Translates the current track's lyrics once and shares the result with every lyrics surface.
///
/// On macOS 26+ it translates on its own with an installed language pair, so it works even when
/// no lyrics window is key. On macOS 15 it relies on a SwiftUI `translationTask` attached by a view.
@MainActor
final class LyricsTranslationStore: ObservableObject {
    static let shared = LyricsTranslationStore()

    enum Status: Equatable {
        case idle
        case translating
        case translated
        case sameLanguage
        case needsLanguageDownload
        case unavailable
        case failed
    }

    struct Request: Equatable {
        let key: String
        let lyrics: TrackLyrics
        let source: Locale.Language
        let target: Locale.Language
    }

    @Published private(set) var translations: [Int: String] = [:]
    @Published private(set) var status: Status = .idle
    /// The language pair the current track needs; set even when the pair still has to be downloaded.
    @Published private(set) var currentRequest: Request?

    private var translatedKey: String?
    private var translationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func start(nowPlayingViewModel: NowPlayingViewModel, settings: MediaAndFilesSettingsStore) {
        guard cancellables.isEmpty else { return }

        Publishers.CombineLatest3(
            nowPlayingViewModel.$lyricsState.removeDuplicates(),
            settings.$isLyricsTranslationEnabled.removeDuplicates(),
            settings.$lyricsTranslationLanguage.removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] lyricsState, isEnabled, language in
            self?.update(lyricsState: lyricsState, isEnabled: isEnabled, target: language)
        }
        .store(in: &cancellables)
    }

    /// Re-attempts the current track, for example after the user downloaded a language.
    func retry() {
        guard let request = currentRequest else { return }
        translatedKey = nil
        begin(request)
    }

    private func update(lyricsState: NowPlayingLyricsState, isEnabled: Bool, target: LyricsTranslationLanguage) {
        guard isEnabled,
              case .loaded(let lyrics) = lyricsState,
              lyrics.isSynced,
              !lyrics.lines.isEmpty else {
            cancel(status: .idle)
            currentRequest = nil
            return
        }

        let key = "\(lyrics.trackKey)|\(target.rawValue)"
        guard key != currentRequest?.key else { return }

        guard let source = LyricsLanguageDetector.dominantLanguage(in: lyrics) else {
            cancel(status: .unavailable)
            currentRequest = nil
            return
        }

        guard !LyricsLanguageDetector.isSameLanguage(source, target.language) else {
            cancel(status: .sameLanguage)
            currentRequest = nil
            return
        }

        let request = Request(key: key, lyrics: lyrics, source: source, target: target.language)
        currentRequest = request
        begin(request)
    }

    private func begin(_ request: Request) {
        cancel(status: .translating)

        if #available(macOS 26.0, *) {
            translationTask = Task { [weak self] in
                await self?.translateWithInstalledLanguages(request)
            }
        }
        // On macOS 15 the views' `lyricsTranslationSession()` modifier picks the request up.
    }

    private func cancel(status: Status) {
        translationTask?.cancel()
        translationTask = nil
        translatedKey = nil
        translations = [:]
        self.status = status
    }

    @available(macOS 26.0, *)
    private func translateWithInstalledLanguages(_ request: Request) async {
        let availability = LanguageAvailability()
        guard await availability.status(from: request.source, to: request.target) != .unsupported else {
            guard currentRequest?.key == request.key else { return }
            status = .unavailable
            return
        }
        guard !Task.isCancelled, currentRequest?.key == request.key else { return }

        // Right after launch the availability check can report an installed pair as merely
        // `.supported`, so always try the installed models first and only ask for a download
        // when that actually fails.
        let session = TranslationSession(installedSource: request.source, target: request.target)
        await translate(request, using: session)

        guard status == .failed, currentRequest?.key == request.key else { return }
        if await availability.status(from: request.source, to: request.target) == .supported {
            status = .needsLanguageDownload
        }
    }

    @available(macOS 15.0, *)
    func translate(_ request: Request, using session: TranslationSession) async {
        guard translatedKey != request.key, currentRequest?.key == request.key else { return }
        translatedKey = request.key
        status = .translating

        let requests = request.lyrics.lines.compactMap { line -> TranslationSession.Request? in
            let text = line.text.trimmed
            guard !text.isEmpty else { return nil }
            return TranslationSession.Request(sourceText: text, clientIdentifier: String(line.id))
        }

        do {
            let responses = try await session.translations(from: requests)
            guard currentRequest?.key == request.key else { return }

            var result: [Int: String] = [:]
            for response in responses {
                guard let id = response.clientIdentifier.flatMap(Int.init) else { continue }
                let translated = response.targetText.trimmed
                guard !translated.isEmpty,
                      translated.caseInsensitiveCompare(response.sourceText.trimmed) != .orderedSame else {
                    continue
                }
                result[id] = translated
            }

            translations = result
            status = .translated
        } catch {
            guard currentRequest?.key == request.key else { return }
            translatedKey = nil
            status = .failed
        }
    }
}

enum LyricsLanguageDetector {
    static func dominantLanguage(in lyrics: TrackLyrics) -> Locale.Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(lyrics.lines.map(\.text).joined(separator: "\n"))

        guard let language = recognizer.dominantLanguage, language != .undetermined else {
            return nil
        }
        return Locale.Language(identifier: language.rawValue)
    }

    static func isSameLanguage(_ lhs: Locale.Language, _ rhs: Locale.Language) -> Bool {
        guard lhs.languageCode == rhs.languageCode else { return false }
        guard let lhsScript = lhs.script, let rhsScript = rhs.script else { return true }
        return lhsScript == rhsScript
    }
}

extension View {
    /// On macOS 15 (no window-less translation API), runs the shared store's pending request
    /// through a SwiftUI translation session hosted by this view.
    func lyricsTranslationSession(store: LyricsTranslationStore) -> some View {
        modifier(LyricsTranslationSessionModifier(store: store))
    }

    /// Hosts a session that downloads the current track's language pair, showing the system prompt.
    func lyricsLanguageDownload(store: LyricsTranslationStore, isRequested: Binding<Bool>) -> some View {
        modifier(LyricsLanguageDownloadModifier(store: store, isRequested: isRequested))
    }
}

private struct LyricsTranslationSessionModifier: ViewModifier {
    @ObservedObject var store: LyricsTranslationStore

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
        } else if #available(macOS 15.0, *) {
            content.modifier(LegacyTranslationTaskModifier(store: store))
        } else {
            content
        }
    }
}

@available(macOS 15.0, *)
private struct LegacyTranslationTaskModifier: ViewModifier {
    @ObservedObject var store: LyricsTranslationStore
    @State private var configuration: TranslationSession.Configuration?

    func body(content: Content) -> some View {
        content
            .translationTask(configuration) { session in
                guard let request = store.currentRequest else { return }
                await store.translate(request, using: session)
            }
            .onAppear {
                updateConfiguration()
            }
            .onChange(of: store.currentRequest?.key) { _, _ in
                updateConfiguration()
            }
    }

    private func updateConfiguration() {
        guard let request = store.currentRequest else {
            configuration = nil
            return
        }

        if configuration?.source == request.source, configuration?.target == request.target {
            configuration?.invalidate()
        } else {
            configuration = TranslationSession.Configuration(source: request.source, target: request.target)
        }
    }
}

private struct LyricsLanguageDownloadModifier: ViewModifier {
    @ObservedObject var store: LyricsTranslationStore
    @Binding var isRequested: Bool

    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.modifier(LanguageDownloadTaskModifier(store: store, isRequested: $isRequested))
        } else {
            content
        }
    }
}

@available(macOS 15.0, *)
private struct LanguageDownloadTaskModifier: ViewModifier {
    @ObservedObject var store: LyricsTranslationStore
    @Binding var isRequested: Bool
    @State private var configuration: TranslationSession.Configuration?

    func body(content: Content) -> some View {
        content
            .translationTask(configuration) { session in
                do {
                    try await session.prepareTranslation()
                    store.retry()
                } catch {}
                isRequested = false
            }
            .onChange(of: isRequested) { _, newValue in
                guard newValue, let request = store.currentRequest else {
                    isRequested = false
                    return
                }

                if configuration?.source == request.source, configuration?.target == request.target {
                    configuration?.invalidate()
                } else {
                    configuration = TranslationSession.Configuration(source: request.source, target: request.target)
                }
            }
    }
}
