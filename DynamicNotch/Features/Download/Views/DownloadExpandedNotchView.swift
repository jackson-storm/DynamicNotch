//
//  DownloadExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

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
