//
//  DownloadNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct DownloadNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    @ObservedObject var downloadViewModel: DownloadViewModel
    @ObservedObject var settings: MediaAndFilesSettingsStore
    
    var body: some View {
        HStack {
            image
            Spacer()
            indicator
        }
        .padding(.leading, isNotchlessScreen ? 7.scaled(by: scale) : 12.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? trailingPadding.scaled(by: scale) : 14.scaled(by: scale))
    }
    
    @ViewBuilder
    private var image: some View {
        if let url = download?.url {
            DownloadFileThumbnailView(url: url, size: isNotchlessScreen ? 20 : 25)
        } else {
            Image(systemName: "document.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    private var indicator: some View {
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
                circleSize: isNotchlessScreen ? 16 : 18,
                circleLineWidth: 3,
                percentFontSize: 14
            )
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
    
    private var download: DownloadModel? {
        downloadViewModel.primaryDownload
    }
    
    private var indicatorStyle: DownloadProgressIndicatorStyle {
        settings.downloadsProgressIndicatorStyle
    }
    
    private var trailingPadding: CGFloat {
        switch settings.downloadsProgressIndicatorStyle {
        case .percent:
            6
        case .circle:
            5
        }
    }
}
