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
            if appearanceStyle == .minimal {
                if let url = download?.url {
                    DownloadFileThumbnailView(url: url, size: isDynamicIsland ? 20 : 25)
                } else {
                    Image(systemName: "document.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: isDynamicIsland ? 20 : 25, height: isDynamicIsland ? 20 : 25)
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
                        circleSize: isDynamicIsland ? 16 : 18,
                        circleLineWidth: 3,
                        percentFontSize: appearanceStyle == .minimal ? 14 : 12
                    )
                    
                    if appearanceStyle == .detailed {
                        Text(speedLabel)
                            .font(.system(size: isDynamicIsland ? 8 : 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.accentColor.opacity(0.8).gradient)
                            .lineLimit(1)
                    }
                }
                .padding(.trailing, isDynamicIsland ? 2.scaled(by: scale) : 0)
            }
        }
        .padding(.vertical, 10)
        .padding(.leading, isDynamicIsland ? 8.scaled(by: scale) : 12.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 4.scaled(by: scale) : 12.scaled(by: scale))
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
}
