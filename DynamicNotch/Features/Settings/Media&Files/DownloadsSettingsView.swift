import SwiftUI

struct DownloadsSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    @ObservedObject var downloadViewModel: DownloadViewModel
    
    var body: some View {
        SettingsPageScrollView {
            downloadActivity
        }
    }
    
    private var downloadActivity: some View {
        SettingsCard(
            title: "Download activity",
            subtitle: "Show live download progress from monitored folders in the notch."
        ) {
            SettingsToggleRow(
                title: "Downloads live activity",
                description: "Show a live activity while files are being downloaded to monitored folders like Downloads, Desktop, and Documents.",
                systemImage: "arrow.down.doc.fill",
                color: .purple,
                isOn: $mediaSettings.isDownloadsLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.downloads"
            )
        }
    }
}
