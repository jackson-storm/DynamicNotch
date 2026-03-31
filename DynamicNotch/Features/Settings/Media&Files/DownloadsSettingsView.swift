import SwiftUI

struct DownloadsSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    @ObservedObject var downloadViewModel: DownloadViewModel
    
    var body: some View {
        SettingsPageScrollView {
            downloadActivity
            downloadAppearance
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
    
    private var downloadAppearance: some View {
        SettingsCard(
            title: "Download appearance",
            subtitle: "Preview the download notch and adjust its accent stroke."
        ) {
            NotchPreview(
                width: 340,
                height: 128,
                topCornerRadius: 24,
                bottomCornerRadius: 34,
                showsStroke: appearanceSettings.isShowNotchStrokeEnabled,
                strokeColor: mediaSettings.isDownloadsDefaultStrokeEnabled ?
                    .white.opacity(0.2) :
                        .accentColor.opacity(0.3),
                strokeWidth: CGFloat(appearanceSettings.notchStrokeWidth)
            ) {
                DownloadExpandedPreviewNotchView()
            }
            
            SettingsToggleRow(
                title: "Use default stroke color",
                description: "Use the default notch stroke color instead of the blue download accent.",
                systemImage: "paintbrush.pointed.fill",
                color: .indigo,
                isOn: $mediaSettings.isDownloadsDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.downloads.defaultStroke"
            )
        }
    }
}
