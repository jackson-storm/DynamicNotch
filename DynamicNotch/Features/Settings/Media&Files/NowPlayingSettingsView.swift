import SwiftUI

struct NowPlayingSettingsView: View {
    @ObservedObject var settings: MediaAndFilesSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            playbackActivity
            playerAppearance
        }
    }
    
    private var playbackActivity: some View {
        SettingsCard(
            title: "Playback activity",
            subtitle: "Keep playback controls in the notch while media is playing."
        ) {
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
    
    private var playerAppearance: some View {
        SettingsCard(title: "Player appearance") {
            NowPlayingAppearancePreview(settings: settings)
            
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

            SettingsToggleRow(
                title: "Artwork-tinted stroke",
                description: "Color the notch stroke using the current artwork palette.",
                systemImage: "stroke.line.diagonal",
                color: .indigo,
                isOn: $settings.isNowPlayingArtworkStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.nowPlaying.artworkStroke"
            )
        }
    }
}

private struct NowPlayingAppearancePreview: View {
    @ObservedObject var settings: MediaAndFilesSettingsStore
    
    private let highlightColor = Color(red: 0.98, green: 0.77, blue: 0.31)
    private let baseColor = Color(red: 0.96, green: 0.48, blue: 0.2)
    
    var body: some View {
        let appearance = settings.nowPlayingAppearanceOptions
        let progressGradient = LinearGradient(
            colors: [highlightColor, baseColor],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        SettingsNotchPreview(
            width: 410,
            height: 190,
            previewWidth: .infinity,
            previewHeight: 215,
            topCornerRadius: 32,
            bottomCornerRadius: 42,
            backgroundStyle: .black,
            showsStroke: true,
            strokeColor: appearance.usesArtworkStrokeTint ? baseColor.opacity(0.3) : .white.opacity(0.2),
            strokeWidth: 1.5,
            lightBackgroundImage: Image("backgroundLight"),
            darkBackgroundImage: Image("backgroundDark")
        ) {
            VStack(spacing: 16) {
                HStack(spacing: 15) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [baseColor, highlightColor],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white.opacity(0.82))
                        }
                        .frame(width: 62, height: 62)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .center, spacing: 10) {
                            Text("Midnight Echoes")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                            
                            Spacer(minLength: 0)
                            
                            HStack(alignment: .bottom, spacing: 3) {
                                ForEach([9.0, 7.0, 10.0, 6.0, 10.0], id: \.self) { height in
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [highlightColor, baseColor],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 3, height: height)
                                }
                            }
                            .frame(height: 18, alignment: .bottom)
                            
                        }
                        Text("Debug Ensemble")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 10) {
                    Text("01:21")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(appearance.usesArtworkTint ? highlightColor : .white.opacity(0.4))
                    
                    GeometryReader { proxy in
                        let trackHeight: CGFloat = 7
                        
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
                    .frame(height: 18)
                    
                    Text("03:34")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(appearance.usesArtworkTint ? baseColor : .white.opacity(0.4))
                }
                
                ZStack {
                    HStack(spacing: 25) {
                        previewControlButton(systemImage: "backward.fill", fontSize: 22)
                        previewControlButton(systemImage: "pause.fill", fontSize: 32)
                        previewControlButton(systemImage: "forward.fill", fontSize: 22)
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
                    .padding(.horizontal, 5)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 50)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
    }
    
    private func previewControlButton(systemImage: String, fontSize: CGFloat) -> some View {
        ZStack {
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 42, height: 42)
    }
    
    private func previewSideButton(systemImage: String) -> some View {
        ZStack {
            Image(systemName: systemImage)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.white.opacity(0.52))
        }
        .frame(width: 42, height: 42)
    }
}
