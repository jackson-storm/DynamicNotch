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
    let mediaAndFilesSettings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    let minimumExpandedSize: CGSize

    init(notchViewModel: NotchViewModel, settings: HomePageSettingsStore, homePages: HomePages,
         localTimerViewModel: LocalTimerViewModel, nowPlayingViewModel: NowPlayingViewModel,
         mediaAndFilesSettings: MediaAndFilesSettingsStore, applicationSettings: ApplicationSettingsStore,
         minimumExpandedSize: CGSize = .zero) {
        self.notchViewModel = notchViewModel
        self.settings = settings
        self.homePages = homePages
        self.localTimerViewModel = localTimerViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.mediaAndFilesSettings = mediaAndFilesSettings
        self.applicationSettings = applicationSettings
        self.minimumExpandedSize = minimumExpandedSize
    }

    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    var isExpandable: Bool { true }
    var usesContentResizeEffect: Bool { false }
    
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
        case .screenshots, .calculator, .sound:
            return ToolHomePageNotchContent(page: homePages)
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
    
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        activePageContent.expandedDynamicIslandCornerRadius(baseHeight: baseHeight)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        activePageContent.dynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        HomePageNavigationLayout.expandedSize(
            preferred: activePageContent.expandedDynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight),
            minimum: minimumExpandedSize
        )
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        HomePageNavigationLayout.expandedSize(
            preferred: activePageContent.expandedSize(baseWidth: baseWidth, baseHeight: baseHeight),
            minimum: minimumExpandedSize
        )
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            HomePageNotchView(
                notchViewModel: notchViewModel,
                settings: settings,
                localTimerViewModel: localTimerViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                mediaAndFilesSettings: mediaAndFilesSettings,
                applicationSettings: applicationSettings,
                initialPage: homePages,
                minimumExpandedSize: minimumExpandedSize
            )
        )
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}
