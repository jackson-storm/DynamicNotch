import SwiftUI

struct DownloadsSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Download activity",
                subtitle: "Track active file transfers from monitored folders in the notch."
            ) {
                SettingsToggleRow(
                    title: "Downloads live activity",
                    description: "Show an activity while files are actively being written in monitored folders like Downloads, Desktop, and Documents.",
                    systemImage: "arrow.down.doc.fill",
                    color: .blue,
                    isOn: $generalSettingsViewModel.isDownloadsLiveActivityEnabled,
                    accessibilityIdentifier: "settings.activities.live.downloads"
                )
            }
        }
    }
}
