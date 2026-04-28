//
//  LockScreenNowPlayingPanel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/15/26.
//

import SwiftUI

struct LockScreenNowPlayingPanelView: View {
    static let panelSize = CGSize(width: 340, height: 180)
    
    private static let expandedPanelHeight: CGFloat = panelSize.height - 20
    private static let expandedArtworkSize: CGFloat = 500
    private static let expandedArtworkSpacing: CGFloat = 90
    private static let expandedStackLift: CGFloat = 160
    private static let expandedClockHeight: CGFloat = 76
    private static let expandedClockArtworkSpacing: CGFloat = 20
    private static let panelCenterYOffset: CGFloat = (Self.panelSize.height / 2) + 80
    
    let snapshot: NowPlayingSnapshot
    let artworkImage: NSImage?
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    @ObservedObject var animator: LockScreenPanelAnimator
    
    @State private var scrubProgress: CGFloat?
    @State private var onTapArtwork: Bool = false
    
    private let animationTick: TimeInterval = 1.0 / 10.0
    
    var body: some View {
        ZStack {
            if onTapArtwork {
                ZStack {
                    Color.black
                    NowPlayingArtworkBackground(
                        artworkImage: resolvedArtworkImage,
                        blurRadius: 200,
                        darkeningOpacity: 0.6,
                        saturation: 1.45,
                        scale: 1
                    )
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
            expandedContent
                .offset(y: Self.panelCenterYOffset)
        }
        .opacity(animator.isPresented ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var expandedContent: some View {
        ZStack {
            if onTapArtwork {
                VStack {
                    TimelineView(.periodic(from: .now, by: 30)) { context in
                        ExpandedLockScreenClockView(
                            date: context.date,
                            width: Self.expandedArtworkSize,
                            height: Self.expandedClockHeight
                        )
                    }
                    expandedArtworkButton
                }
                .offset(y: expandedArtworkOffset)
                .transition(.scale(scale: 0.82).combined(with: .opacity))
            }

            playerPanel
                .offset(y: playerPanelOffset)
        }
        .frame(
            width: Self.panelSize.width,
            height: onTapArtwork ? expandedPresentationHeight : Self.panelSize.height,
            alignment: .center
        )
    }

    private var playerPanel: some View {
        LockScreenNowPlayingView(
            settings: settingsViewModel.mediaAndFiles,
            nowPlayingViewModel: nowPlayingViewModel,
            onTapArtwork: $onTapArtwork
        )
        .frame(
            width: Self.panelSize.width,
            height: onTapArtwork ? Self.expandedPanelHeight : Self.panelSize.height,
            alignment: .topLeading
        )
        .background {
            panelBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .environment(\.colorScheme, .dark)
        .shadow(color: .black.opacity(0.24), radius: 26, x: 0, y: 14)
    }

    private var expandedArtworkButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.65)) {
                onTapArtwork = false
            }
        }) {
            ArtworkView(
                nowPlayingViewModel: nowPlayingViewModel,
                width: Self.expandedArtworkSize,
                height: Self.expandedArtworkSize,
                cornerRadius: 30
            )
            .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 16)
        }
        .buttonStyle(PlaybackSourceButtonStyle())
    }

    private var expandedPresentationHeight: CGFloat {
        Self.expandedClockHeight +
        Self.expandedClockArtworkSpacing +
        Self.expandedArtworkSize +
        Self.expandedArtworkSpacing +
        Self.expandedPanelHeight
    }

    private var expandedClockOffset: CGFloat {
        expandedArtworkOffset -
        (Self.expandedArtworkSize / 2) -
        (Self.expandedClockHeight / 2) -
        Self.expandedClockArtworkSpacing
    }

    private var expandedArtworkOffset: CGFloat {
        -((Self.expandedPanelHeight + Self.expandedArtworkSpacing) / 2) - Self.expandedStackLift
    }

    private var playerPanelOffset: CGFloat {
        onTapArtwork ? ((Self.expandedArtworkSize + Self.expandedArtworkSpacing) / 2) - Self.expandedStackLift : 0
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

    private var resolvedArtworkImage: NSImage? {
        artworkImage ?? nowPlayingViewModel.artworkImage
    }
}

private struct ExpandedLockScreenClockView: View {
    let date: Date
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 58) {
            Spacer()
            
            Text(timeString)
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            
            Text(dateString)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
            
            Spacer()
        }
        .frame(width: width, height: height, alignment: .leading)
        .shadow(color: .black.opacity(0.28), radius: 10, x: 0, y: 4)
    }

    private var timeString: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.dateFormat = "EEE d MMM"

        return formatter.string(from: date).localizedCapitalizedFirstLetter
    }
}

private extension String {
    var localizedCapitalizedFirstLetter: String {
        guard let first else { return self }

        return String(first).localizedUppercase + dropFirst()
    }
}

private struct LockScreenNowPlayingView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @Binding var onTapArtwork: Bool
    
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
                if onTapArtwork == false {
                    Button(action: {
                        withAnimation(.spring(response: 0.6)) {
                            onTapArtwork = true
                        }
                    }) {
                        ArtworkView(nowPlayingViewModel: nowPlayingViewModel, width: 60, height: 60, cornerRadius: 10)
                    }
                    .buttonStyle(PlaybackSourceButtonStyle())
                }
                
                HStack(alignment: .top, spacing: 10) {
                    Button(action: {
                        withAnimation(.spring(response: 0.6)) {
                            onTapArtwork.toggle()
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            MarqueeText(
                                .constant(displayTitle(for: snapshot)),
                                font: .system(size: 16, weight: .medium),
                                nsFont: .headline,
                                textColor: .white.opacity(0.8),
                                backgroundColor: .clear,
                                minDuration: 2.0,
                                frameWidth: onTapArtwork ? 260.scaled(by: scale) : 180.scaled(by: scale)
                            )

                            MarqueeText(
                                .constant(displayArtist(for: snapshot)),
                                font: .system(size: 14),
                                nsFont: .headline,
                                textColor: .white.opacity(0.5),
                                backgroundColor: .clear,
                                minDuration: 3.0,
                                frameWidth: onTapArtwork ? 260.scaled(by: scale) : 180.scaled(by: scale)
                            )
                        }
                    }
                    .buttonStyle(PlaybackSourceButtonStyle())

                    Spacer(minLength: 0)
                    
                    EqualizerView(
                        isPlaying: snapshot.isPlaying,
                        mode: settings.nowPlayingEqualizerMode,
                        palette: nowPlayingViewModel.artworkPalette,
                        trackSeed: snapshot.waveSeed,
                        audioLevels: nowPlayingViewModel.audioReactiveLevels,
                        date: date,
                        width: onTapArtwork ? 2.3 : 2.7,
                        height: onTapArtwork ? 3.3 : 3.7
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
                        fontSize: 21
                    )
                    
                    Spacer()
                    
                    AudioOutputRoutePickerButton(
                        nowPlayingViewModel: nowPlayingViewModel,
                        width: 42,
                        height: 42,
                        fontSize: 21
                    )
                }
                .padding(.horizontal, 5)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
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
