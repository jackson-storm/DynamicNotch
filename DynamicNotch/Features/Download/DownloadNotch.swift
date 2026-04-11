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
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 65, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 130, height: baseHeight + 120)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(DownloadNotchView(downloadViewModel: downloadViewModel))
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(DownloadExpandedNotchView(downloadViewModel: downloadViewModel))
    }
}

struct DownloadNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var downloadViewModel: DownloadViewModel
    
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
        download?.displayName ?? "Incoming File"
    }
    
    private var trailingLabel: String {
        let extraCount = downloadViewModel.additionalDownloadCount
        
        if extraCount > 0 {
            return "+\(extraCount)"
        }
        
        return download?.directoryName ?? "Files"
    }
    
    private var sizeLabel: String {
        guard let download else { return "--" }
        return Self.byteCountFormatter.string(fromByteCount: download.byteCount)
    }
    
    var body: some View {
        HStack {
            if let url = download?.url {
                DownloadFileThumbnailView(url: url, size: 25)
            }
            Spacer()
            DownloadActivityIndicator(progress: download?.progress ?? 0.08)
                .padding(.trailing, 2)
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
            HStack(spacing: 8) {
                Text(Self.byteCountFormatter.string(fromByteCount: download.byteCount))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))

                Spacer(minLength: 8)

                Text(totalSizeLabel(for: download))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

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

private struct DownloadActivityIndicator: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: max(0.06, min(progress, 1)))
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
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 18, height: 18)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}
