internal import AppKit
import QuickLookThumbnailing
import SwiftUI

enum DownloadEvent: Equatable {
    case started
    case stopped
}

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
