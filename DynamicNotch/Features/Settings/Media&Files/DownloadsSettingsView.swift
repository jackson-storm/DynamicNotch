import SwiftUI

struct DownloadsSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    @ObservedObject var downloadViewModel: DownloadViewModel

    private var isDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }
    
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

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsStrokeToggleRow(
                title: "Default stroke",
                description: "Use the standard white notch stroke instead of the accent-colored download stroke.",
                isOn: $mediaSettings.isDownloadsDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.downloads.defaultStroke"
            )
            .disabled(isDefaultStrokeLocked)
            .opacity(isDefaultStrokeLocked ? 0.5 : 1)
        }
    }
}
