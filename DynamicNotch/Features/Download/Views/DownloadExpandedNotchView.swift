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
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func header(for download: DownloadModel) -> some View {
        HStack(alignment: .center, spacing: 2) {
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

    private func speedLabel(for download: DownloadModel) -> String {
        guard download.bytesPerSecond > 0 else { return "0 KB/s" }
        return "\(Self.byteCountFormatter.string(fromByteCount: download.bytesPerSecond))/s"
    }
    
    private func progressLabel(for progress: Double) -> String {
           "\(Int((clampedProgress(progress) * 100).rounded()))%"
       }

    private func clampedProgress(_ progress: Double) -> Double {
        min(max(progress, 0), 1)
    }
}
