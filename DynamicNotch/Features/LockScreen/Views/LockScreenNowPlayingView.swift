//
//  LockScreenNowPlayingPanel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/15/26.
//

import SwiftUI

struct LockScreenNowPlayingPanelView: View {
    static let panelSize = CGSize(width: 340, height: 200)
    
    let snapshot: NowPlayingSnapshot
    let artworkImage: NSImage?
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    @ObservedObject var animator: LockScreenPanelAnimator
    
    @State private var scrubProgress: CGFloat?
    
    private let animationTick: TimeInterval = 1.0 / 10.0
    
    var body: some View {
        LockScreenNowPlayingView(
            settings: settingsViewModel.mediaAndFiles,
            nowPlayingViewModel: nowPlayingViewModel
        )
        .frame(width: Self.panelSize.width, height: Self.panelSize.height, alignment: .topLeading)
        .background {
            panelBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .environment(\.colorScheme, .dark)
        .shadow(color: .black.opacity(0.24), radius: 26, x: 0, y: 14)
        .opacity(animator.isPresented ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private var panelBackground: some View {
        LockScreenWidgetSurface(
            style: settingsViewModel.lockScreen.widgetAppearanceStyle,
            tintStyle: settingsViewModel.lockScreen.widgetTintStyle,
            brightness: settingsViewModel.lockScreen.widgetBackgroundBrightness,
            cornerRadius: 28
        )
    }
}

private struct LockScreenNowPlayingView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    @State private var scrubProgress: CGFloat?
    private let audioReactiveVisibilitySource = "nowPlaying.lockScreen.panel"
    
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
        
        return TimelineView(.periodic(from: .now, by: animationTick(for: snapshot))) { context in
            timelineContent(snapshot: snapshot, at: context.date)
        }
        .onAppear {
            nowPlayingViewModel.setAudioReactiveVisualizationActive(
                true,
                source: audioReactiveVisibilitySource
            )
        }
        .onDisappear {
            nowPlayingViewModel.setAudioReactiveVisualizationActive(
                false,
                source: audioReactiveVisibilitySource
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
        
        return VStack {
            HStack(spacing: 15) {
                ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 60, height: 60, cornerRadius: 10)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .center, spacing: 10) {
                        MarqueeText(
                            .constant(displayTitle(for: snapshot)),
                            font: .system(size: 16, weight: .medium),
                            nsFont: .headline,
                            textColor: .primary.opacity(0.8),
                            backgroundColor: .clear,
                            minDuration: 2.0,
                            frameWidth: 170.scaled(by: scale)
                        )
                        
                        Spacer(minLength: 0)
                        
                        EqualizerView(
                            isPlaying: snapshot.isPlaying,
                            mode: settings.nowPlayingEqualizerMode,
                            palette: nowPlayingViewModel.artworkPalette,
                            trackSeed: snapshot.waveSeed,
                            audioLevels: nowPlayingViewModel.audioReactiveLevels,
                            date: date,
                            width: 2.7,
                            height: 3.7
                        )
                    }
                    
                    MarqueeText(
                        .constant(displayArtist(for: snapshot)),
                        font: .system(size: 14),
                        nsFont: .headline,
                        textColor: .secondary,
                        backgroundColor: .clear,
                        minDuration: 3.0,
                        frameWidth: 170.scaled(by: scale)
                    )
                }
            }
            Spacer()
            
            PlayerProgressBar(
                progress: displayedProgress,
                displayedElapsedTime: displayedElapsedTime,
                duration: snapshot.duration,
                isInteractive: snapshot.duration > 0,
                tintGradient: nil,
                primaryColor: .secondary,
                secondaryColor: .secondary,
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
                        height: 42
                    ) {
                        nowPlayingViewModel.previousTrack()
                    }
                    
                    PlayerControlButton(
                        systemImage: snapshot.isPlaying ? "pause.fill" : "play.fill",
                        fontSize: 32,
                        width: 42,
                        height: 42
                    ) {
                        nowPlayingViewModel.togglePlayPause()
                    }
                    
                    PlayerControlButton(
                        systemImage: "forward.fill",
                        fontSize: 22,
                        width: 42,
                        height: 42
                    ) {
                        nowPlayingViewModel.nextTrack()
                    }
                }
                
                HStack {
                    FavoriteTrackButton(
                        nowPlayingViewModel: nowPlayingViewModel,
                        width: 42,
                        height: 42,
                        fontSize: 22
                    )
                    
                    Spacer()
                    
                    AudioOutputRoutePickerButton(
                        nowPlayingViewModel: nowPlayingViewModel,
                        width: 42,
                        height: 42,
                        fontSize: 22
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
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
    
    private func animationTick(for snapshot: NowPlayingSnapshot) -> TimeInterval {
        snapshot.isPlaying ? (1.0 / 14.0) : 0.5
    }
    
    private func playbackStatusColor(for snapshot: NowPlayingSnapshot) -> Color {
        if nowPlayingViewModel.snapshot == nil {
            return .white.opacity(0.48)
        }
        
        return snapshot.isPlaying ?
        Color(red: 0.97, green: 0.73, blue: 0.32) :
            .white.opacity(0.48)
    }
}
