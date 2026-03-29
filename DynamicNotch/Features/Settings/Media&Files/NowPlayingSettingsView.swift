import SwiftUI

struct NowPlayingSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Playback activity",
                subtitle: "Keep music and media controls anchored in the notch while playback is active."
            ) {
                SettingsToggleRow(
                    title: "Now Playing live activity",
                    description: "Keep the media player pinned in the notch while playback is active.",
                    systemImage: "music.note",
                    color: .red,
                    isOn: $generalSettingsViewModel.isNowPlayingLiveActivityEnabled,
                    accessibilityIdentifier: "settings.activities.live.nowPlaying"
                )
            }
        }
    }
}
