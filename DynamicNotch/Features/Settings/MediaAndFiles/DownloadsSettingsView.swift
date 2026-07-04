import SwiftUI

struct DownloadsSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    private var isDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }
    

    
    var body: some View {
        SettingsPageScrollView {
            downloadActivity
            downloadAppearance
        }
    }
    
    private var downloadActivity: some View {
        SettingsCard(title: "Download activity") {
            SettingsToggleRow(
                title: "Downloads live activity",
                description: "Show a live activity while files are being downloaded to monitored folders like Downloads, Desktop, and Documents.",
                systemImage: "arrow.down.circle.fill",
                color: .blue,
                isOn: $mediaSettings.isDownloadsLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.downloads"
            )
        }
    }
    
    private var downloadAppearance: some View {
        SettingsCard(title: "Download appearance") {
            SettingsMenuRow(
                title: "Progress indicator",
                description: "Choose whether download progress uses a percentage label or a circular ring.",
                options: Array(DownloadProgressIndicatorStyle.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.activities.live.downloads.progressIndicator",
                selection: $mediaSettings.downloadsProgressIndicatorStyle
            )
            
            Divider().opacity(0.6)
            
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
