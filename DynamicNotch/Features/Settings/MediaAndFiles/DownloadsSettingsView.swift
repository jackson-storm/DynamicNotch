import SwiftUI

struct DownloadsSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    private var isDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }
    
    private var downloadPreviewStrokeColor: Color {
        guard appearanceSettings.isShowNotchStrokeEnabled else {
            return .clear
        }
        
        if appearanceSettings.isDefaultActivityStrokeEnabled || mediaSettings.isDownloadsDefaultStrokeEnabled {
            return .white.opacity(0.2)
        }
        
        return .accentColor.opacity(0.3)
    }
    
    private let previewDownload = DownloadSettingsPreviewModel.settingsPreview
    
    private var speedLabel: String {
        guard previewDownload.bytesPerSecond > 0 else { return "0 KB/s" }
        return "\(Self.byteCountFormatter.string(fromByteCount: previewDownload.bytesPerSecond))/s"
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
                systemImage: "arrow.down.doc.fill",
                color: .purple,
                isOn: $mediaSettings.isDownloadsLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.downloads"
            )
        }
    }
    
    private var downloadAppearance: some View {
        SettingsCard(title: "Download appearance") {
            CustomPicker(
                selection: $mediaSettings.downloadsAppearanceStyle,
                options: Array(DownloadAppearanceStyle.allCases),
                title: { $0.title },
                headerTitle: "Download style",
                headerDescription: "Choose how much information the download activity shows at a glance.",
                itemHeight: 82,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                downloadAppearancePickerContent(for: style, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.activities.live.downloads.style")
            
            Divider().opacity(0.6)
            
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
    
    @ViewBuilder
    private func downloadAppearancePickerContent(for style: DownloadAppearanceStyle, isSelected: Bool) -> some View {
        switch style {
        case .minimal:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(downloadPreviewStrokeColor, lineWidth: 1)
                    }
                
                HStack(spacing: 8) {
                    Image(systemName: "document.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    DownloadProgressIndicatorView(
                        progress: previewDownload.progress,
                        indicatorStyle: mediaSettings.downloadsProgressIndicatorStyle,
                        barWidth: 34,
                        barHeight: 4,
                        circleSize: 16,
                        circleLineWidth: 2.5,
                        percentFontSize: 12
                    )
                }
                .padding(.leading, 10)
                .padding(.trailing, 7)
            }
            .frame(width: 160, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
            
        case .detailed:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(downloadPreviewStrokeColor, lineWidth: 1)
                    }
                
                HStack(spacing: 8) {
                    Text(previewDownload.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(1)
                    
                    Spacer(minLength: 8)
                    
                    if mediaSettings.downloadsProgressIndicatorStyle == .circle {
                        Text(speedLabel)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.accentColor.opacity(0.8).gradient)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        DownloadProgressIndicatorView(
                            progress: previewDownload.progress,
                            indicatorStyle: mediaSettings.downloadsProgressIndicatorStyle,
                            barWidth: 34,
                            barHeight: 4,
                            circleSize: 16,
                            circleLineWidth: 2.5,
                            percentFontSize: 12
                        )
                    } else {
                        VStack(alignment: .trailing, spacing: 0) {
                            DownloadProgressIndicatorView(
                                progress: previewDownload.progress,
                                indicatorStyle: mediaSettings.downloadsProgressIndicatorStyle,
                                barWidth: 34,
                                barHeight: 4,
                                circleSize: 16,
                                circleLineWidth: 2.5,
                                percentFontSize: 10
                            )
                            Text(speedLabel)
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.accentColor.opacity(0.8).gradient)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
                .padding(.leading, 10)
                .padding(.trailing, mediaSettings.downloadsProgressIndicatorStyle == .circle ? 7 : 10)
            }
            .frame(width: 210, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }
    
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()
}

private struct DownloadSettingsPreviewModel {
    let displayName: String
    let progress: Double
    let bytesPerSecond: Int64

    static let settingsPreview = DownloadSettingsPreviewModel(
        displayName: "Photo.png",
        progress: 0.60,
        bytesPerSecond: 12_845_056
    )
}
