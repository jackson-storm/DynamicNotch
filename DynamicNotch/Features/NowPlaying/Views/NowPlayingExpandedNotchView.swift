//
//  NowPlayingExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct NowPlayingExpandedNotchView: View {
    @Environment(\.notchScale) var scale
    @Environment(\.isNotchlessScreen) var isNotchlessScreen
    @Environment(\.locale) private var locale
    
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    let onOpenPlaybackSource: @MainActor () -> Void
    
    @State private var scrubProgress: CGFloat?
    @ObservedObject private var translationStore = LyricsTranslationStore.shared
    private let detailedPresentationSource = "nowPlaying.notch.expanded"
    private let lyricsPresentationSource = "nowPlaying.notch.expanded.lyrics"
    
    private var resolvedSnapshot: NowPlayingSnapshot {
        nowPlayingViewModel.snapshot ?? NowPlayingSnapshot(
            title: locale.dn("notch.nowPlaying.nothingPlaying", fallback: "Nothing Playing"),
            artist: locale.dn("notch.nowPlaying.startPlayback", fallback: "Start playback to see live metadata"),
            album: "Debug Preview",
            duration: 0,
            elapsedTime: 0,
            playbackRate: 0,
            artworkData: nil,
            refreshedAt: .now
        )
    }
    
    var body: some View {
        let snapshot = resolvedSnapshot

        return TimelineView(.periodic(from: .now, by: progressTick(for: snapshot))) { context in
            timelineContent(snapshot: snapshot, at: context.date)
        }
        .onAppear {
            nowPlayingViewModel.setDetailedPresentationActive(
                true,
                source: detailedPresentationSource
            )
            syncLyricsPresentationState()
        }
        .onDisappear {
            nowPlayingViewModel.setDetailedPresentationActive(
                false,
                source: detailedPresentationSource
            )
            nowPlayingViewModel.setLyricsPresentationActive(false, source: lyricsPresentationSource)
        }
        .onChange(of: settings.isNowPlayingNotchLyricsEnabled) { _, _ in
            syncLyricsPresentationState()
        }
        .lyricsTranslationSession(store: translationStore)
    }

    private var showsLyricsTranslation: Bool {
        settings.isNowPlayingNotchLyricsEnabled &&
        settings.isLyricsTranslationEnabled &&
        settings.isNotchLyricsTranslationEnabled
    }

    private func syncLyricsPresentationState() {
        nowPlayingViewModel.setLyricsPresentationActive(
            settings.isNowPlayingNotchLyricsEnabled,
            source: lyricsPresentationSource
        )
    }

    private func timelineContent(snapshot: NowPlayingSnapshot, at date: Date) -> some View {
        let elapsedTime = nowPlayingViewModel.snapshot != nil ?
        nowPlayingViewModel.elapsedTime(at: date) :
        snapshot.elapsedTime
        let progress = progressValue(elapsedTime: elapsedTime, duration: snapshot.duration)
        let displayedProgress = min(max(scrubProgress ?? progress, 0), 1)
        let displayedElapsedTime = snapshot.duration > 0 ?
        TimeInterval(displayedProgress) * snapshot.duration :
        elapsedTime
        let appearance = settings.nowPlayingAppearanceOptions

        return VStack(spacing: 12) {
            Spacer()
            headerSection(snapshot: snapshot, appearance: appearance)

            if appearance.showsLyrics {
                let lyricLine = currentLyricLine(at: elapsedTime - nowPlayingViewModel.lyricsTotalDelay)
                NotchLyricLineView(
                    lineID: lyricLine.id,
                    text: lyricLine.text,
                    translation: lyricLine.translation,
                    showsTranslation: showsLyricsTranslation
                )
                .equatable()
            }
            
            PlayerProgressBar(
                progress: displayedProgress,
                displayedElapsedTime: displayedElapsedTime,
                duration: snapshot.duration,
                isInteractive: snapshot.duration > 0,
                tintGradient: {
                    switch appearance.progressTintStyle {
                    case .default:
                        return nil
                    case .artwork:
                        return nowPlayingViewModel.artworkPalette.equalizerGradient
                    case .systemAccent:
                        return LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }(),
                primaryColor: progressTimeColor(isPrimary: true, appearance: appearance),
                secondaryColor: progressTimeColor(isPrimary: false, appearance: appearance),
                onScrubChanged: { newProgress in
                    scrubProgress = newProgress
                },
                onScrubEnded: { newProgress in
                    nowPlayingViewModel.seek(to: snapshot.duration * TimeInterval(newProgress))
                    scrubProgress = nil
                }
            )
            controlsSection(snapshot: snapshot, appearance: appearance)
        }
        .padding(.horizontal, isNotchlessScreen ? 22 : 55)
        .padding(.bottom, isNotchlessScreen ? 16 : 18)
    }

    @ViewBuilder
    private func headerSection(snapshot: NowPlayingSnapshot, appearance: NowPlayingAppearanceOptions) -> some View {
        HStack(spacing: 15) {
            Button(action: {
                openPlaybackSource()
            }) {
                ArtworkView(
                    nowPlayingViewModel: nowPlayingViewModel,
                    width: 60,
                    height: 60,
                    cornerRadius: 10,
                    usesFlipAnimation: appearance.usesArtwork3DEffect
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlaybackSourceButtonStyle())
            .disabled(!nowPlayingViewModel.canOpenPlaybackSource)

            HStack(alignment: .top, spacing: 10) {
                Button(action: {
                    openPlaybackSource()
                }) {
                    VStack(alignment: .leading, spacing: 2) {
                        MarqueeText(
                            .constant(displayTitle(for: snapshot)),
                            font: .system(size: 16, weight: .medium),
                            nsFont: .headline,
                            textColor: .white,
                            backgroundColor: .clear,
                            minDuration: 2.0,
                            frameWidth: 170
                        )

                        MarqueeText(
                            .constant(displayArtist(for: snapshot)),
                            font: .system(size: 14),
                            nsFont: .headline,
                            textColor: .white.opacity(0.5),
                            backgroundColor: .clear,
                            minDuration: 3.0,
                            frameWidth: 170
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlaybackSourceButtonStyle())
                .disabled(!nowPlayingViewModel.canOpenPlaybackSource)

                Spacer()

                LightweightNowPlayingEqualizerView(
                    isPlaying: snapshot.isPlaying,
                    colors: [
                        nowPlayingViewModel.artworkPalette.equalizerHighlightColor,
                        nowPlayingViewModel.artworkPalette.equalizerBaseColor
                    ],
                    barHeight: 23,
                    barWidth: 2.7
                )
                .frame(width: 23, height: 18)
            }
        }
    }

    @ViewBuilder
    private func controlsSection(snapshot: NowPlayingSnapshot, appearance: NowPlayingAppearanceOptions) -> some View {
        ZStack {
            HStack(spacing: 25) {
                PlayerControlButton(
                    systemImage: "backward.fill",
                    fontSize: 22,
                    width: 42,
                    height: 42,
                    feedbackStyle: .backward
                ) {
                    nowPlayingViewModel.previousTrack()
                }

                PlayerControlButton(
                    systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill",
                    fontSize: 32,
                    width: 42,
                    height: 42,
                    feedbackStyle: .playPause
                ) {
                    nowPlayingViewModel.togglePlayPause()
                }

                PlayerControlButton(
                    systemImage: "forward.fill",
                    fontSize: 22,
                    width: 42,
                    height: 42,
                    feedbackStyle: .forward
                ) {
                    nowPlayingViewModel.nextTrack()
                }
            }

            HStack {
                if appearance.showsFavoriteButton {
                    FavoriteTrackButton(
                        nowPlayingViewModel: nowPlayingViewModel,
                        width: 42,
                        height: 42,
                        fontSize: 21
                    )
                }

                Spacer()

                if appearance.showsOutputDeviceButton {
                    AudioOutputRoutePickerButton(
                        nowPlayingViewModel: nowPlayingViewModel,
                        width: 42,
                        height: 42,
                        fontSize: 21
                    )
                }
            }
            .padding(.horizontal, 3)
        }
    }
    
    private func displayTitle(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.title.trimmed.isEmpty ? locale.dn("notch.nowPlaying.unknownTrack", fallback: "Unknown Track") : snapshot.title
    }
    
    private func displayArtist(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.artist.trimmed.isEmpty ? locale.dn("notch.nowPlaying.unknownArtist", fallback: "Unknown Artist") : snapshot.artist
    }
    
    private func displayAlbum(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.album.trimmed.isEmpty ? locale.dn("notch.nowPlaying.unknownAlbum", fallback: "Unknown Album") : snapshot.album
    }
    
    private func currentLyricLine(at elapsedTime: TimeInterval) -> (id: Int, text: String?, translation: String?) {
        guard case .loaded(let lyrics) = nowPlayingViewModel.lyricsState,
              let index = lyrics.activeLineIndex(at: elapsedTime),
              lyrics.lines.indices.contains(index) else {
            return (-1, nil, nil)
        }

        let line = lyrics.lines[index]
        if let startTime = line.startTime, startTime > elapsedTime + 0.18 {
            return (-1, nil, nil)
        }

        let text = line.text.trimmed
        let translation = showsLyricsTranslation ? translationStore.translations[line.id] : nil
        return (index, text.isEmpty ? nil : text, translation)
    }

    private func progressValue(elapsedTime: TimeInterval, duration: TimeInterval) -> CGFloat {
        guard duration > 0 else { return 0 }
        return min(max(CGFloat(elapsedTime / duration), 0), 1)
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "--:--" }
        
        let totalSeconds = max(0, Int(time.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func progressTimeColor(isPrimary: Bool, appearance: NowPlayingAppearanceOptions) -> Color {
        switch appearance.progressTintStyle {
        case .default:
            return .white.opacity(0.4)
        case .artwork:
            let nsColor = isPrimary ?
            nowPlayingViewModel.artworkPalette.equalizerHighlightColor :
            nowPlayingViewModel.artworkPalette.equalizerBaseColor
            return Color(nsColor: nsColor)
        case .systemAccent:
            return isPrimary ? .accentColor : .accentColor.opacity(0.7)
        }
    }
    
    private func playbackStatusColor(for snapshot: NowPlayingSnapshot) -> Color {
        if nowPlayingViewModel.snapshot == nil {
            return .white.opacity(0.48)
        }
        
        return snapshot.isPlaying ?
        Color(red: 0.97, green: 0.73, blue: 0.32) :
            .white.opacity(0.48)
    }

    private func progressTick(for snapshot: NowPlayingSnapshot) -> TimeInterval {
        snapshot.isPlaying ? 0.25 : 30.0
    }

    private func openPlaybackSource() {
        guard nowPlayingViewModel.canOpenPlaybackSource else { return }
        nowPlayingViewModel.openPlaybackSource()
        if !applicationSettings.isCloseAtFocusLiveActivityEnabled {
            onOpenPlaybackSource()
        }
    }
}

private struct NotchLyricLineView: View, Equatable {
    static let translationHeight: CGFloat = 18

    let lineID: Int
    let text: String?
    let translation: String?
    let showsTranslation: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(text ?? "♪")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(text == nil ? 0.35 : 0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .truncationMode(.tail)
                    .frame(height: 18)

                if showsTranslation {
                    Text(translation ?? "")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .truncationMode(.tail)
                        .frame(height: 16)
                }
            }
            .frame(maxWidth: .infinity)
            .id(lineID)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
        }
        .frame(height: showsTranslation ? 18 + Self.translationHeight : 18)
        .clipped()
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: lineID)
    }
}
