internal import AppKit
import QuickLookThumbnailing
import SwiftUI

enum DownloadEvent: Equatable {
    case started
    case stopped
}

struct DownloadNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Media.download.id
    
    let downloadViewModel: DownloadViewModel
    let settingsViewModel: SettingsViewModel
    
    var priority: Int { NotchContentRegistry.Media.download.priority }
    var isExpandable: Bool { true }
    
    var windowLink: (@MainActor () -> Void)? {
        return {
            downloadViewModel.openPrimaryDownloadFolder()
        }
    }
    
    private var indicatorStyle: DownloadProgressIndicatorStyle {
        settingsViewModel.mediaAndFiles.downloadsProgressIndicatorStyle
    }
    
    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: CGFloat = indicatorStyle == .circle ? 70 : 90
        return .init(width: baseWidth + width, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: CGFloat = indicatorStyle == .circle ? 60 : 90
        return .init(width: baseWidth + width, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 150, height: baseHeight + 65)
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 230, height: baseHeight + 65)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.45
    }
    
    @MainActor
    func compactView() -> AnyView {
        AnyView(
            DownloadNotchView(
                downloadViewModel: downloadViewModel,
                settings: settingsViewModel.mediaAndFiles
            )
        )
    }
    
    @MainActor
    func expandedView() -> AnyView {
        AnyView(DownloadExpandedNotchView(downloadViewModel: downloadViewModel))
    }
}
