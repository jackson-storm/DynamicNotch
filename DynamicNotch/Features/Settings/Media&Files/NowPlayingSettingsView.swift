import SwiftUI

struct NowPlayingSettingsView: View {
    @ObservedObject var settings: MediaAndFilesSettingsStore

    var body: some View {
        SettingsPageScrollView {
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
    }
}
