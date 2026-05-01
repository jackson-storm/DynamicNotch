//
//  NowPlayingExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct NowPlayingExpandedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    let onOpenPlaybackSource: @MainActor () -> Void
    
    @State private var scrubProgress: CGFloat?
    private let detailedPresentationSource = "nowPlaying.notch.expanded"
    
    private var resolvedSnapshot: NowPlayingSnapshot {
        nowPlayingViewModel.snapshot ?? NowPlayingSnapshot(
            title: "Nothing Playing",
            artist: "Start playback to see live metadata",
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
        }
        .onDisappear {
            nowPlayingViewModel.setDetailedPresentationActive(
                false,
                source: detailedPresentationSource
            )
        }
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
        let appearance = settings.resolvedNowPlayingAppearanceOptions(
            isDefaultActivityStrokeEnabled: applicationSettings.isDefaultActivityStrokeEnabled
        )

        return VStack {
            Spacer()

            HStack(spacing: 15) {
                Button(action: {
                    openPlaybackSource()
                }) {
                    ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 60, height: 60, cornerRadius: 10)
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
                                textColor: .white.opacity(0.8),
                                backgroundColor: .clear,
                                minDuration: 2.0,
                                frameWidth: 170.scaled(by: scale)
                            )

                            MarqueeText(
                                .constant(displayArtist(for: snapshot)),
                                font: .system(size: 14),
                                nsFont: .headline,
                                textColor: .white.opacity(0.5),
                                backgroundColor: .clear,
                                minDuration: 3.0,
                                frameWidth: 170.scaled(by: scale)
                            )
                        }
                    }
                    .buttonStyle(PlaybackSourceButtonStyle())
                    .disabled(!nowPlayingViewModel.canOpenPlaybackSource)

                    Spacer(minLength: 0)

                    LightweightNowPlayingEqualizerView(
                        isPlaying: snapshot.isPlaying,
                        color: nowPlayingViewModel.artworkPalette.equalizerBaseColor,
                        barHeight: 23,
                        barWidth: 2.7
                    )
                    .frame(width: 23, height: 18)
                }
            }
            Spacer()

            PlayerProgressBar(
                progress: displayedProgress,
                displayedElapsedTime: displayedElapsedTime,
                duration: snapshot.duration,
                isInteractive: snapshot.duration > 0,
                tintGradient: appearance.usesArtworkTint ? nowPlayingViewModel.artworkPalette.equalizerGradient : nil,
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

            Spacer()

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
                .padding(.horizontal, 5)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 55)
        .padding(.top, 25)
        .padding(.bottom, 15)
    }
    
    private func displayTitle(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.title.trimmed.isEmpty ? "Unknown Track" : snapshot.title
    }
    
    private func displayArtist(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.artist.trimmed.isEmpty ? "Unknown Artist" : snapshot.artist
    }
    
    private func displayAlbum(for snapshot: NowPlayingSnapshot) -> String {
        snapshot.album.trimmed.isEmpty ? "Unknown Album" : snapshot.album
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
        guard appearance.usesArtworkTint else {
            return .white.opacity(0.4)
        }

        let nsColor = isPrimary ?
        nowPlayingViewModel.artworkPalette.equalizerHighlightColor :
        nowPlayingViewModel.artworkPalette.equalizerBaseColor

        return Color(nsColor: nsColor)
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
        snapshot.isPlaying ? 1.0 : 30.0
    }

    private func openPlaybackSource() {
        guard nowPlayingViewModel.canOpenPlaybackSource else { return }

        nowPlayingViewModel.openPlaybackSource()
        onOpenPlaybackSource()
    }
}
