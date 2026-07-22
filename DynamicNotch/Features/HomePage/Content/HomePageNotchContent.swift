//
//  HomePageNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI
internal import EventKit

struct HomePageNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.HomePage.active.id
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let homePages: HomePages
    let localTimerViewModel: LocalTimerViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let fileConverterViewModel: FileConverterViewModel
    let mediaAndFilesSettings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore

    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    var isExpandable: Bool { true }
    
    var strokeColor: Color {
        if notchViewModel.isDisplayingExpandedLiveActivity {
            return .white.opacity(0.2)
        }
        return .white.opacity(0)
    }
    
    private var activePageContent: any NotchContentProtocol {
        switch homePages {
        case .camera:
            return CameraActiveNotchContent()
        case .localTimer:
            return LocalTimerHomePageNotchContent()
        case .vpn:
            return VpnHomePageNotchContent()
        case .systemStats:
            return SystemStatsHomePageNotchContent()
        case .fileConverter:
            return FileConverterHomePageNotchContent(
                fileConverterViewModel: fileConverterViewModel,
                onRequestCollapse: { [weak notchViewModel] in
                    notchViewModel?.handleOutsideClick()
                }
            )
        }
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        activePageContent.expandedCornerRadius(baseRadius: baseRadius)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth, height: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        return .init(width: baseWidth, height: baseHeight)
    }
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        if let custom = activePageContent as? DynamicIslandCustomizable {
            return custom.expandedDynamicIslandCornerRadius(baseHeight: baseHeight)
        }
        return baseHeight * 0.2
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        activePageContent.expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        if let custom = activePageContent as? DynamicIslandCustomizable {
            return custom.expandedDynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
        }
        return .init(width: baseWidth + 180, height: baseHeight + 125)
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            HomePageNotchView(
                notchViewModel: notchViewModel,
                settings: settings,
                localTimerViewModel: localTimerViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                fileConverterViewModel: fileConverterViewModel,
                mediaAndFilesSettings: mediaAndFilesSettings,
                applicationSettings: applicationSettings,
                initialPage: homePages
            )
        )
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}
