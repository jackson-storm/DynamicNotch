import SwiftUI

struct FloatingLyricsView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore

    let onHide: () -> Void

    @ObservedObject private var translationStore = LyricsTranslationStore.shared
    @State private var delayBadgeText: String?
    @State private var delayBadgeToken = UUID()

    var body: some View {
        let isPlaying = nowPlayingViewModel.snapshot?.isPlaying ?? false
        let appearance = settings.floatingLyricsAppearance

        TimelineView(.periodic(from: .now, by: isPlaying ? 0.25 : 30)) { context in
            FloatingLyricsContentView(
                trackLine: trackLine,
                lines: visibleLines(at: context.date, appearance: appearance),
                appearance: appearance,
                accentColor: Color(nsColor: nowPlayingViewModel.artworkPalette.equalizerHighlightColor),
                badge: delayBadgeText
            )
            .equatable()
        }
        .lyricsTranslationSession(store: translationStore)
        .onChange(of: nowPlayingViewModel.lyricsDelayChangeCount) { _, _ in
            showDelayBadge()
        }
        .contextMenu {
            Menu("Lyrics Delay (\(Self.formattedDelay(nowPlayingViewModel.lyricsTrackDelay)))") {
                Button("Show Lyrics Later (+0.5s)") {
                    nowPlayingViewModel.adjustLyricsTrackDelay(by: 0.5)
                }
                Button("Show Lyrics Earlier (−0.5s)") {
                    nowPlayingViewModel.adjustLyricsTrackDelay(by: -0.5)
                }
                Button("Reset Song Delay") {
                    nowPlayingViewModel.resetLyricsTrackDelay()
                }
            }
            Divider()
            Toggle("Translate Lyrics", isOn: $settings.isLyricsTranslationEnabled)
            Toggle("Show Next Line", isOn: $settings.isFloatingLyricsNextLineVisible)
            Toggle("Show Track Info", isOn: $settings.isFloatingLyricsTrackInfoVisible)
            Toggle("Lock Position", isOn: $settings.isFloatingLyricsPositionLocked)
            Divider()
            Button("Reload Lyrics") {
                nowPlayingViewModel.reloadLyrics()
            }
            Button("Hide Floating Lyrics", action: onHide)
        }
    }

    static func formattedDelay(_ delay: TimeInterval) -> String {
        String(format: "%+.1fs", delay)
    }

    private func showDelayBadge() {
        let token = UUID()
        delayBadgeToken = token
        delayBadgeText = "Delay \(Self.formattedDelay(nowPlayingViewModel.lyricsTotalDelay))"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            guard delayBadgeToken == token else { return }
            delayBadgeText = nil
        }
    }

    private var trackLine: String {
        guard let snapshot = nowPlayingViewModel.snapshot else { return "" }
        let parts = [snapshot.title.trimmed, snapshot.artist.trimmed].filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }

    private var translationPlaceholder: String {
        switch translationStore.status {
        case .needsLanguageDownload:
            return "Download this language in Settings to translate"
        case .failed:
            return "Translation unavailable"
        default:
            return ""
        }
    }

    private func visibleLines(at date: Date, appearance: FloatingLyricsAppearance) -> FloatingLyricsLines {
        switch nowPlayingViewModel.lyricsState {
        case .idle, .loading:
            return .message("Loading lyrics…")
        case .notFound:
            return .message("No lyrics found")
        case .failed:
            return .message("Couldn't load lyrics · right-click to retry")
        case .loaded(let lyrics):
            guard lyrics.isSynced else {
                return .message("Lyrics aren't synced for this track")
            }

            let playbackTime = nowPlayingViewModel.lyricsPlaybackTime(at: date)
            guard let index = lyrics.activeLineIndex(at: playbackTime),
                  lyrics.lines.indices.contains(index) else {
                return .message("♪")
            }

            let line = lyrics.lines[index]
            if let startTime = line.startTime, startTime > playbackTime + 0.18 {
                return .synced(id: -1, current: "♪", translation: nil, next: line.text.trimmed)
            }

            let nextIndex = lyrics.lines.index(after: index)
            let next = lyrics.lines.indices.contains(nextIndex) ? lyrics.lines[nextIndex].text.trimmed : ""
            let current = line.text.trimmed
            let translation = appearance.isTranslationEnabled ?
                (translationStore.translations[line.id] ?? translationPlaceholder) :
                nil

            return .synced(
                id: index,
                current: current.isEmpty ? "♪" : current,
                translation: translation,
                next: next
            )
        }
    }
}

enum FloatingLyricsLines: Equatable {
    case message(String)
    case synced(id: Int, current: String, translation: String?, next: String)
}

struct FloatingLyricsContentView: View, Equatable {
    let trackLine: String
    let lines: FloatingLyricsLines
    let appearance: FloatingLyricsAppearance
    let accentColor: Color
    var badge: String? = nil

    private var currentLineColor: Color {
        switch appearance.colorStyle {
        case .white:
            return .white
        case .artwork:
            return accentColor
        case .accent:
            return .accentColor
        case .custom:
            return Color(lyricsHex: appearance.customColorHex) ?? .white
        }
    }

    var body: some View {
        VStack(alignment: appearance.alignment.horizontalAlignment, spacing: 6) {
            if appearance.showsTrackInfo {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accentColor)

                    Text(trackLine)
                        .font(.system(size: 11, weight: .medium, design: appearance.fontDesign.design))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(height: 14)
            }

            ZStack(alignment: appearance.alignment.frameAlignment) {
                switch lines {
                case .message(let message):
                    lyricText(message, size: appearance.nextLineFontSize, weight: .semibold, color: .white.opacity(0.4))

                case .synced(let id, let current, let translation, let next):
                    VStack(alignment: appearance.alignment.horizontalAlignment, spacing: 0) {
                        lyricText(current, size: appearance.fontSize, weight: .bold, color: currentLineColor)

                        if appearance.isTranslationEnabled {
                            lyricText(
                                translation ?? "",
                                size: appearance.translationFontSize,
                                weight: .medium,
                                color: .white.opacity(0.7)
                            )
                            .padding(.top, 3)
                        }

                        if appearance.showsNextLine {
                            lyricText(
                                next,
                                size: appearance.nextLineFontSize,
                                weight: .semibold,
                                color: .white.opacity(0.35)
                            )
                            .padding(.top, 4)
                        }
                    }
                    .id(id)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: appearance.alignment.frameAlignment)
            .clipped()
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: lines)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: appearance.alignment.frameAlignment)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(appearance.backgroundOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(appearance.backgroundOpacity > 0.05 ? 0.08 : 0), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if let badge {
                Text(badge)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.18)))
                    .padding(10)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: badge)
    }

    private func lyricText(_ text: String, size: CGFloat, weight: Font.Weight, color: Color) -> some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: appearance.fontDesign.design))
            .foregroundStyle(color)
            .shadow(color: .black.opacity(appearance.showsShadow ? 0.55 : 0), radius: 3, y: 1)
            .multilineTextAlignment(appearance.alignment.textAlignment)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(height: size * 1.3)
    }
}
