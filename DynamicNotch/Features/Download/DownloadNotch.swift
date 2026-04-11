internal import AppKit
import QuickLookThumbnailing
import SwiftUI

struct DownloadNotchContent: NotchContentProtocol {
    let id = "download.active"
    let downloadViewModel: DownloadViewModel
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { 82 }
    var isExpandable: Bool { true }
    
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled || settingsViewModel.mediaAndFiles.isDownloadsDefaultStrokeEnabled ?
        .white.opacity(0.2) :
        .accentColor.opacity(0.30)
    }
    
    var expandedOffsetXTransition: CGFloat { -80 }
    var expandedOffsetYTransition: CGFloat { -60 }

    private var appearanceStyle: DownloadAppearanceStyle {
        settingsViewModel.mediaAndFiles.downloadsAppearanceStyle
    }

    private var indicatorStyle: DownloadProgressIndicatorStyle {
        settingsViewModel.mediaAndFiles.downloadsProgressIndicatorStyle
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: CGFloat

        switch appearanceStyle {
        case .minimal:
            width = indicatorStyle == .circle ? 70 : 90
        case .detailed:
            width = 180
        }

        return .init(width: baseWidth + width, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 130, height: baseHeight + 120)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(
            DownloadNotchView(
                downloadViewModel: downloadViewModel,
                settings: settingsViewModel.mediaAndFiles
            )
        )
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(DownloadExpandedNotchView(downloadViewModel: downloadViewModel))
    }
}

struct DownloadNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var downloadViewModel: DownloadViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore
    
    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    private var download: DownloadModel? {
        downloadViewModel.primaryDownload
    }
    
    private var resolvedFileName: String {
        let baseName = download?.displayName ?? "Incoming File"
        let extraCount = downloadViewModel.additionalDownloadCount
        return extraCount > 0 ? "\(baseName) +\(extraCount)" : baseName
    }

    private var appearanceStyle: DownloadAppearanceStyle {
        settings.downloadsAppearanceStyle
    }

    private var indicatorStyle: DownloadProgressIndicatorStyle {
        settings.downloadsProgressIndicatorStyle
    }

    private var collapsedBarWidth: CGFloat {
        switch appearanceStyle {
        case .minimal:
            return 34
        case .detailed:
            return 50
        }
    }

    private var titleWidth: CGFloat {
        switch appearanceStyle {
        case .minimal:
            return 0
        case .detailed:
            return 85
        }
    }

    private var speedLabel: String {
        guard let download, download.bytesPerSecond > 0 else { return "0 KB/s" }
        return "\(Self.byteCountFormatter.string(fromByteCount: download.bytesPerSecond))/s"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if appearanceStyle == .minimal {
                if let url = download?.url {
                    DownloadFileThumbnailView(url: url, size: 25)
                } else {
                    Image(systemName: "doc.zipper")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(width: 25, height: 25)
                }
            }

            if appearanceStyle == .detailed {
                MarqueeText(
                    .constant(resolvedFileName),
                    font: .system(size: 13, weight: .medium),
                    nsFont: .body,
                    textColor: .white.opacity(0.8),
                    backgroundColor: .clear,
                    minDuration: 0.5,
                    frameWidth: titleWidth
                )
                .lineLimit(1)
            }

            Spacer()

            if settings.downloadsProgressIndicatorStyle == .circle {
                if appearanceStyle == .detailed {
                    Text(speedLabel)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.accentColor.opacity(0.8).gradient)
                        .lineLimit(1)
                }
                
                DownloadProgressIndicatorView(
                    progress: download?.progress ?? 0.08,
                    indicatorStyle: indicatorStyle,
                    barWidth: collapsedBarWidth,
                    barHeight: 4,
                    circleSize: 18,
                    circleLineWidth: 3,
                    percentFontSize: 14
                )
                .padding(.trailing, 2)
                
            } else {
                VStack(alignment: .trailing, spacing: 0) {
                    DownloadProgressIndicatorView(
                        progress: download?.progress ?? 0.08,
                        indicatorStyle: indicatorStyle,
                        barWidth: collapsedBarWidth,
                        barHeight: 4,
                        circleSize: 18,
                        circleLineWidth: 3,
                        percentFontSize: appearanceStyle == .minimal ? 14 : 12
                    )
                    
                    if appearanceStyle == .detailed {
                        Text(speedLabel)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.accentColor.opacity(0.8).gradient)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.horizontal, 12.scaled(by: scale))
    }
}

struct DownloadExpandedNotchView: View {
    @ObservedObject var downloadViewModel: DownloadViewModel

    private var primaryDownload: DownloadModel? {
        downloadViewModel.primaryDownload
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            if let primaryDownload {
                DownloadExpandedNotchContentView(download: primaryDownload)
            }
        }
    }
}

struct DownloadExpandedPreviewNotchView: View {
    var body: some View {
        DownloadExpandedNotchContentView(download: .settingsPreview)
    }
}

private struct DownloadExpandedNotchContentView: View {
    @Environment(\.notchScale) private var scale
    
    let download: DownloadModel

    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            header(for: download)
            progressSection(for: download)
        }
        .padding(.horizontal, 45)
        .padding(.bottom, 25)
    }

    @ViewBuilder
    private func header(for download: DownloadModel) -> some View {
        HStack(alignment: .top, spacing: 2) {
            DownloadFileThumbnailView(url: download.url, size: 45)

            VStack(alignment: .leading, spacing: 4) {
                MarqueeText(
                    .constant(download.displayName),
                    font: .system(size: 14, weight: .semibold),
                    nsFont: .body,
                    textColor: .white.opacity(0.8),
                    backgroundColor: .clear,
                    minDuration: 2.0,
                    frameWidth: 130.scaled(by: scale)
                )

                Text(download.directoryName)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
            }
            .padding(.leading, 6)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(progressLabel(for: download.progress))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                Text(speedLabel(for: download))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color.accentColor.opacity(0.8).gradient)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }

    @ViewBuilder
    private func progressSection(for download: DownloadModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sizeLabels(for: download)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.45),
                                    Color.accentColor
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(16, proxy.size.width * CGFloat(clampedProgress(download.progress))))
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private func sizeLabels(for download: DownloadModel) -> some View {
        HStack(spacing: 8) {
            Text(Self.byteCountFormatter.string(fromByteCount: download.byteCount))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))

            Spacer(minLength: 8)

            Text(totalSizeLabel(for: download))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func speedLabel(for download: DownloadModel) -> String {
        guard download.bytesPerSecond > 0 else { return "0 KB/s" }
        return "\(Self.byteCountFormatter.string(fromByteCount: download.bytesPerSecond))/s"
    }

    private func totalSizeLabel(for download: DownloadModel) -> String {
        Self.byteCountFormatter.string(fromByteCount: download.estimatedTotalByteCount)
    }
    
    private func progressLabel(for progress: Double) -> String {
           "\(Int((clampedProgress(progress) * 100).rounded()))%"
       }

    private func clampedProgress(_ progress: Double) -> Double {
        min(max(progress, 0), 1)
    }
}

private extension DownloadModel {
    static let settingsPreview = DownloadModel(
        url: URL(fileURLWithPath: "/tmp/DynamicNotchPreview.zip"),
        displayName: "DynamicNotchPreview.zip",
        directoryName: "Downloads",
        byteCount: 148_320_256,
        estimatedTotalByteCount: 247_200_427,
        progress: 0.60,
        startedAt: .now.addingTimeInterval(-24),
        lastUpdatedAt: .now,
        isTemporaryFile: false,
        bytesPerSecond: 12_845_056
    )
}

private struct DownloadFileThumbnailView: View {
    let url: URL
    let size: CGFloat
    
    @State private var thumbnailImage: NSImage?

    private var fallbackIcon: NSImage {
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = CGSize(width: size, height: size)
        return icon
    }

    var body: some View {
        Group {
            if let thumbnailImage {
                Image(nsImage: thumbnailImage)
                    .resizable()
            } else {
                Image(nsImage: fallbackIcon)
                    .resizable()
            }
        }
        .frame(width: size, height: size)
        .task(id: url.path) {
            loadThumbnailIfNeeded()
        }
    }

    private func loadThumbnailIfNeeded() {
        guard thumbnailImage == nil else { return }

        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: size, height: size),
            scale: scale,
            representationTypes: .thumbnail
        )

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
            guard let representation else { return }

            DispatchQueue.main.async {
                thumbnailImage = representation.nsImage
            }
        }
    }
}

struct DownloadProgressIndicatorView: View {
    let progress: Double
    let indicatorStyle: DownloadProgressIndicatorStyle
    let barWidth: CGFloat
    let barHeight: CGFloat
    let circleSize: CGFloat
    let circleLineWidth: CGFloat
    let percentFontSize: CGFloat

    private var clampedProgress: CGFloat {
        max(0.06, min(CGFloat(progress), 1))
    }
    
    var body: some View {
        Group {
            switch indicatorStyle {
            case .percent:
                Text("\(Int((clampedProgress * 100).rounded()))%")
                    .font(.system(size: percentFontSize))
                    .foregroundStyle(Color.accentColor.gradient)

            case .circle:
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: circleLineWidth)
                    
                    Circle()
                        .trim(from: 0, to: clampedProgress)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    .accentColor.opacity(0.3),
                                    .accentColor.opacity(0.9),
                                    .accentColor
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(
                                lineWidth: circleLineWidth,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: circleSize, height: circleSize)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: clampedProgress)
    }
}
