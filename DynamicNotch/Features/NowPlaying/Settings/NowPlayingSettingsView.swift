import SwiftUI

struct NowPlayingSettingsView: View {
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    private var pauseHideDelayRange: ClosedRange<Double> {
        Double(SettingsStoreBase.pauseHideDelayRange.lowerBound)...Double(SettingsStoreBase.pauseHideDelayRange.upperBound)
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
        SettingsCard(title: "settings.nowPlaying.card.playback") {
            SettingsToggleRow(
                title: "settings.nowPlaying.liveActivity.title",
                description: "settings.nowPlaying.liveActivity.desc",
                systemImage: "play.fill",
                color: .red,
                isOn: $settings.isNowPlayingLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.nowPlaying"
            )
            
            Divider().opacity(0.6)
            
            SettingsMenuRow(
                title: "settings.nowPlaying.playbackSource.title",
                description: "settings.nowPlaying.playbackSource.desc",
                options: Array(NowPlayingSourceFilter.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.nowPlaying.sourceFilter",
                selection: $settings.nowPlayingSourceFilter
            )
        }
    }
    
    private var pausedPlaybackBehavior: some View {
        SettingsCard(title: "settings.nowPlaying.card.paused") {
            SettingsToggleRow(
                title: "settings.nowPlaying.withoutCloseTimer.title",
                description: "settings.nowPlaying.withoutCloseTimer.desc",
                systemImage: "pause.circle",
                color: .orange,
                isOn: isWithoutCloseTimer,
                accessibilityIdentifier: "settings.activities.live.nowPlaying.withoutCloseTimer"
            )
            
            Divider().opacity(0.6)
            
            SettingsSliderRow(
                title: "settings.nowPlaying.closeDelay.title",
                description: "settings.nowPlaying.closeDelay.desc",
                range: pauseHideDelayRange,
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
        SettingsCard(title: "settings.nowPlaying.card.playerAppearance") {
            NowPlayingAppearancePreview(
                settings: settings,
                applicationSettings: applicationSettings
            )
            
            Divider().opacity(0.6)
            
            SettingsToggleRow(
                title: "settings.nowPlaying.hideFavorite.title",
                description: "settings.nowPlaying.hideFavorite.desc",
                systemImage: "star.slash.fill",
                color: .red,
                iconBadge: false,
                isOn: Binding(
                    get: { !settings.isNowPlayingFavoriteButtonVisible },
                    set: { settings.isNowPlayingFavoriteButtonVisible = !$0 }
                ),
                accessibilityIdentifier: "settings.activities.live.nowPlaying.hideFavorite"
            )
            
            Divider().opacity(0.6)
            
            SettingsToggleRow(
                title: "settings.nowPlaying.hideOutputDevice.title",
                description: "settings.nowPlaying.hideOutputDevice.desc",
                systemImage: "airplay.audio",
                color: .red,
                iconBadge: false,
                isOn: Binding(
                    get: { !settings.isNowPlayingOutputDeviceButtonVisible },
                    set: { settings.isNowPlayingOutputDeviceButtonVisible = !$0 }
                ),
                accessibilityIdentifier: "settings.activities.live.nowPlaying.hideOutputDevice"
            )
        }
    }
}

private struct NowPlayingAppearancePreview: View {
    @ObservedObject var settings: MediaAndFilesSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        let appearance = settings.nowPlayingAppearanceOptions
        let showsNotchStroke = applicationSettings.isShowNotchStrokeEnabled
        
        SettingsNotchPreview(
            width: 300,
            height: 170,
            previewHeight: 200,
            сornerRadius: 35,
            strokeColor: showsNotchStroke ? Color.white.opacity(0.2).opacity(applicationSettings.notchStrokeOpacity) : .clear,
            lightBackgroundImage: Image("backgroundLight"),
            darkBackgroundImage: Image("backgroundDark")
        ) {
            VStack(spacing: 13) {
                HStack(spacing: 13) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(width: 55, height: 55)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .center, spacing: 8) {
                            Text(verbatim: "Debug Song Name")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            LightweightNowPlayingEqualizerView(
                                isPlaying: true,
                                colors: [.gray],
                                barHeight: 23,
                                barWidth: 2.7
                            )
                            .frame(width: 23, height: 18)
                        }
                        Text(verbatim: "Debug Autor")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(verbatim: "01:21")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.4))
                    
                    GeometryReader { proxy in
                        let trackHeight: CGFloat = 6
                        
                        ZStack(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(.white.opacity(0.15))
                                .frame(height: trackHeight)
                            
                            Capsule(style: .continuous)
                                .fill(.white.opacity(0.5))
                                .frame(width: proxy.size.width * 0.38, height: trackHeight)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 14)
                    
                    Text(verbatim: "03:34")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.4))
                }
                ZStack {
                    HStack(spacing: 22) {
                        previewControlButton(systemImage: "backward.fill", fontSize: 20)
                        previewControlButton(systemImage: "pause.fill", fontSize: 28)
                        previewControlButton(systemImage: "forward.fill", fontSize: 20)
                    }
                    HStack {
                        if appearance.showsFavoriteButton {previewSideButton(systemImage: "star")}
                        Spacer()
                        if appearance.showsOutputDeviceButton {previewSideButton(systemImage: "airplayaudio")}
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func previewControlButton(systemImage: String, fontSize: CGFloat) -> some View {
        ZStack {
            Image(systemName: systemImage)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 38, height: 38)
    }
    
    private func previewSideButton(systemImage: String) -> some View {
        ZStack {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(width: 34, height: 34)
    }
}
