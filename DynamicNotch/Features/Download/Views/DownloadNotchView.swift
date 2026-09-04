//
//  DownloadNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct DownloadNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    @ObservedObject var downloadViewModel: DownloadViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore
    
    var body: some View {
        HStack {
            if let url = download?.url {
                DownloadFileThumbnailView(url: url, size: isDynamicIsland ? 15 : 25)
            } else {
                Image(systemName: "document.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            if settings.downloadsProgressIndicatorStyle == .circle {
                DownloadProgressIndicatorView(
                    progress: download?.progress ?? 0.08,
                    indicatorStyle: indicatorStyle,
                    barWidth: 34,
                    barHeight: 4,
                    circleSize: 18,
                    circleLineWidth: 3,
                    percentFontSize: 14
                )
            } else {
                DownloadProgressIndicatorView(
                    progress: download?.progress ?? 0.08,
                    indicatorStyle: indicatorStyle,
                    barWidth: 34,
                    barHeight: 4,
                    circleSize: isDynamicIsland ? 16 : 18,
                    circleLineWidth: 3,
                    percentFontSize: 14
                )
            }
        }

        .padding(.leading, isDynamicIsland ? 6.scaled(by: scale) : 12.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 4.scaled(by: scale) : 14.scaled(by: scale))
    }
    
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

    private var indicatorStyle: DownloadProgressIndicatorStyle {
        settings.downloadsProgressIndicatorStyle
    }
}
