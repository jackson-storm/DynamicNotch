import SwiftUI

struct DownloadsSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            downloadActivity
            downloadAppearance
        }
    }
    
    private var downloadActivity: some View {
        SettingsCard(title: "settings.downloads.card.activity") {
            SettingsToggleRow(
                title: "settings.downloads.liveActivity.title",
                description: "settings.downloads.liveActivity.desc",
                systemImage: "arrow.down.circle.fill",
                color: .blue,
                isOn: $mediaSettings.isDownloadsLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.downloads"
            )
        }
    }
    
    private var downloadAppearance: some View {
        SettingsCard(title: "settings.downloads.card.appearance") {
            SettingsMenuRow(
                title: "settings.downloads.progressIndicator.title",
                description: "settings.downloads.progressIndicator.desc",
                options: Array(DownloadProgressIndicatorStyle.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.downloads.progressIndicator",
                selection: $mediaSettings.downloadsProgressIndicatorStyle
            )
        }
    }
}

