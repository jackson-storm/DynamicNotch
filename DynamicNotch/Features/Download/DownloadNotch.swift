internal import AppKit
import QuickLookThumbnailing
import SwiftUI

struct DownloadNotchContent: NotchContentProtocol {
    let id = "download.active"
    let downloadViewModel: DownloadViewModel
    
    var priority: Int { 82 }
    var isExpandable: Bool { true }
    
    var strokeColor: Color { .accentColor.opacity(0.30) }
    
    var offsetXTransition: CGFloat { -80 }
    var expandedOffsetXTransition: CGFloat { -80 }
    var expandedOffsetYTransition: CGFloat { -60 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 70, height: baseHeight)
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

private struct DownloadNotchView: View {
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
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 24)
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            DownloadActivityIndicator(progress: download?.progress ?? 0.08)
        }
        .padding(.horizontal, 14.scaled(by: scale))
    }
}

private struct DownloadExpandedNotchView: View {
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

    private var primaryDownload: DownloadModel? {
        downloadViewModel.primaryDownload
    }

    private var queuedDownloads: [DownloadModel] {
        Array(downloadViewModel.activeDownloads.dropFirst().prefix(3))
    }

    private var remainingQueueCount: Int {
        max(0, downloadViewModel.additionalDownloadCount - queuedDownloads.count)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 16) {
                if let primaryDownload {
                    Spacer()
                    header(for: primaryDownload)
                    progressSection(for: primaryDownload)
                    
                }
            }
            .padding(.horizontal, 45)
            .padding(.bottom, 25)
        }
    }
        
    @ViewBuilder
    private func header(for download: DownloadModel) -> some View {
        HStack(alignment: .top, spacing: 2) {
            DownloadFileThumbnailView(url: download.url)

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
            .foregroundStyle(.blue.opacity(0.8).gradient)
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

private struct DownloadFileThumbnailView: View {
    let url: URL

    @State private var thumbnailImage: NSImage?

    private let size: CGFloat = 45
    private let cornerRadius: CGFloat = 11

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
                    .scaledToFill()
            } else {
                Image(nsImage: fallbackIcon)
                    .resizable()
                    .scaledToFit()
                    .padding(6)
            }
        }
        .frame(width: size, height: size)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.1))
        )
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
    
    private enum Metrics {
        static let size: CGFloat = 18
        static let lineWidth: CGFloat = 3
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.16), lineWidth: Metrics.lineWidth)
            
            Circle()
                .trim(from: 0, to: max(0.06, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        colors: [
                            .accentColor.opacity(0.35),
                            .accentColor.opacity(0.9),
                            .accentColor
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: Metrics.lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: Metrics.size, height: Metrics.size)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}
