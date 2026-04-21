import SwiftUI

struct NowPlayingSettingsView: View {
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }

    private var isArtworkStrokeLocked: Bool {
        applicationSettings.isDefaultActivityStrokeEnabled
    }

    private var isWithoutCloseTimer: Binding<Bool> {
        Binding(
            get: { !settings.isNowPlayingPauseHideTimerEnabled },
            set: { settings.isNowPlayingPauseHideTimerEnabled = !$0 }
        )
    }
    
    var body: some View {
        SettingsPageScrollView {
            playbackActivity
            pausedPlaybackBehavior
            playerAppearance
        }
    }
    
    private var playbackActivity: some View {
        SettingsCard(title: "Playback activity") {
            SettingsToggleRow(
                title: "Now Playing live activity",
                description: "Show the Now Playing live activity while audio or video playback is active.",
                systemImage: "music.note",
                color: .red,
                isOn: $settings.isNowPlayingLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.nowPlaying"
            )
        }
    }

    private var pausedPlaybackBehavior: some View {
        SettingsCard(title: "Paused playback") {
            SettingsToggleRow(
                title: "Without close timer",
                description: "Keep Now Playing visible in the notch while playback is paused.",
                systemImage: "pause.circle",
                color: .orange,
                isOn: isWithoutCloseTimer,
                accessibilityIdentifier: "settings.activities.live.nowPlaying.withoutCloseTimer"
            )

            Divider().opacity(0.6)

            SettingsSliderRow(
                title: "Close delay",
                description: "Choose how long the paused player stays visible before the notch closes.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.live.nowPlaying.closeDelay",
                value: Binding(
                    get: { Double(settings.nowPlayingPauseHideDelay) },
                    set: { settings.nowPlayingPauseHideDelay = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isNowPlayingPauseHideTimerEnabled || !settings.isNowPlayingLiveActivityEnabled)
            .opacity(settings.isNowPlayingPauseHideTimerEnabled && settings.isNowPlayingLiveActivityEnabled ? 1 : 0.5)
        }
    }
    
    private var playerAppearance: some View {
        SettingsCard(title: "Player appearance") {
            NowPlayingAppearancePreview(
                settings: settings,
                applicationSettings: applicationSettings
            )

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "Equalizer mode",
                description: "Choose the standard equalizer or an audio-reactive mode that follows the current system playback.",
                options: Array(NowPlayingEqualizerMode.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.nowPlaying.equalizerMode",
                selection: $settings.nowPlayingEqualizerMode
            )
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.yellow)

                Text("Audio-reactive mode may require Screen Recording permission.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
            }
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.yellow)

                Text("Audio-reactive mode may use more system resources.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
            }
            
            Divider().opacity(0.6)

            SettingsToggleRow(
                title: "Hide favorite",
                description: "Remove the favorite button from the expanded player controls.",
                systemImage: "star.slash.fill",
                color: .pink,
                isOn: Binding(
                    get: { !settings.isNowPlayingFavoriteButtonVisible },
                    set: { settings.isNowPlayingFavoriteButtonVisible = !$0 }
                ),
                accessibilityIdentifier: "settings.activities.live.nowPlaying.hideFavorite"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Hide output device",
                description: "Remove the output device button from the expanded player controls.",
                systemImage: "airplay.audio",
                color: .blue,
                isOn: Binding(
                    get: { !settings.isNowPlayingOutputDeviceButtonVisible },
                    set: { settings.isNowPlayingOutputDeviceButtonVisible = !$0 }
                ),
                accessibilityIdentifier: "settings.activities.live.nowPlaying.hideOutputDevice"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Artwork-tinted progress",
                description: "Color the progress bar and timer labels using the current artwork palette.",
                systemImage: "paintbrush.pointed.fill",
                color: Color(red: 1, green: 0.73, blue: 0.32),
                isOn: $settings.isNowPlayingArtworkTintEnabled,
                accessibilityIdentifier: "settings.activities.live.nowPlaying.artworkTint"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)

            SettingsStrokeToggleRow(
                title: "Artwork-tinted stroke",
                description: "Color the notch stroke using the current artwork palette.",
                isOn: $settings.isNowPlayingArtworkStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.nowPlaying.artworkStroke"
            )
            .disabled(isArtworkStrokeLocked)
            .opacity(isArtworkStrokeLocked ? 0.5 : 1)
        }
    }
}

private struct NowPlayingAppearancePreview: View {
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    private let highlightColor = Color(red: 0.98, green: 0.77, blue: 0.31)
    private let baseColor = Color(red: 0.96, green: 0.48, blue: 0.2)
    
    var body: some View {
        let appearance = settings.resolvedNowPlayingAppearanceOptions(
            isDefaultActivityStrokeEnabled: applicationSettings.isDefaultActivityStrokeEnabled
        )
        let previewEqualizerHeights: [CGFloat] = settings.nowPlayingEqualizerMode == .audioReactive ?
            [6, 12, 8, 11, 7] :
            [8, 6, 9, 5, 9]
        let showsNotchStroke = applicationSettings.isShowNotchStrokeEnabled
        let progressGradient = LinearGradient(
            colors: [highlightColor, baseColor],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        SettingsNotchPreview(
            width: 360,
            height: 168,
            previewHeight: 186,
            topCornerRadius: 28,
            bottomCornerRadius: 38,
            backgroundStyle: .black,
            showsStroke: showsNotchStroke,
            strokeColor: showsNotchStroke
            ? (appearance.usesArtworkStrokeTint ? baseColor.opacity(0.3) : .white.opacity(0.2))
            : .clear,
            strokeWidth: 1.5,
            lightBackgroundImage: Image("backgroundLight"),
            darkBackgroundImage: Image("backgroundDark")
        ) {
            VStack(spacing: 13) {
                HStack(spacing: 13) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [baseColor, highlightColor],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white.opacity(0.82))
                        }
                        .frame(width: 54, height: 54)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("Midnight Echoes")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                            
                            Spacer(minLength: 0)
                            
                            HStack(alignment: .bottom, spacing: 2.5) {
                                ForEach(Array(previewEqualizerHeights.enumerated()), id: \.offset) { entry in
                                    let height = entry.element
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [highlightColor, baseColor],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 2.5, height: height)
                                }
                            }
                            .frame(height: 15, alignment: .bottom)
                            
                        }
                        Text("Debug Ensemble")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 8) {
                    Text("01:21")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(appearance.usesArtworkTint ? highlightColor : .white.opacity(0.4))
                    
                    GeometryReader { proxy in
                        let trackHeight: CGFloat = 6
                        
                        ZStack(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(.white.opacity(0.15))
                                .frame(height: trackHeight)
                            
                            Capsule(style: .continuous)
                                .fill(appearance.usesArtworkTint ? AnyShapeStyle(progressGradient) : AnyShapeStyle(.white.opacity(0.5)))
                                .frame(width: proxy.size.width * 0.38, height: trackHeight)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 14)
                    
                    Text("03:34")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(appearance.usesArtworkTint ? baseColor : .white.opacity(0.4))
                }
                
                ZStack {
                    HStack(spacing: 22) {
                        previewControlButton(systemImage: "backward.fill", fontSize: 20)
                        previewControlButton(systemImage: "pause.fill", fontSize: 28)
                        previewControlButton(systemImage: "forward.fill", fontSize: 20)
                    }
                    
                    HStack {
                        if appearance.showsFavoriteButton {
                            previewSideButton(systemImage: "star")
                        }
                        
                        Spacer()
                        
                        if appearance.showsOutputDeviceButton {
                            previewSideButton(systemImage: "airplayaudio")
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
    }
    
    private func previewControlButton(systemImage: String, fontSize: CGFloat) -> some View {
        ZStack {
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 38, height: 38)
    }
    
    private func previewSideButton(systemImage: String) -> some View {
        ZStack {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.52))
        }
        .frame(width: 34, height: 34)
    }
}
