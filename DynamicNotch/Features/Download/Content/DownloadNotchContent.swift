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
    
    var strokeColor: Color {
        settingsViewModel.isDefaultActivityStrokeEnabled ?
        .white.opacity(0.2) :
        .accentColor.opacity(0.30)
    }
    
    private var indicatorStyle: DownloadProgressIndicatorStyle {
        settingsViewModel.mediaAndFiles.downloadsProgressIndicatorStyle
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: CGFloat = indicatorStyle == .circle ? 70 : 90
        return .init(width: baseWidth + width, height: baseHeight)
    }
    
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 130, height: baseHeight + 65)
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 34)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }
    
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 180, height: baseHeight + 65)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width: CGFloat = indicatorStyle == .circle ? 50 : 70
        return .init(width: baseWidth + width, height: baseHeight)
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
