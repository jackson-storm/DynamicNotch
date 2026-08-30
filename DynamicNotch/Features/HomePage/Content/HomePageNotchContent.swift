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
    let clipboardHistoryViewModel: ClipboardHistoryViewModel
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
        case .mediaPlayer:
            return NowPlayingNotchContent(
                nowPlayingViewModel: nowPlayingViewModel,
                settings: mediaAndFilesSettings,
                applicationSettings: applicationSettings
            )
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
        (top: 30, bottom: 38)
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
        baseHeight * 0.28
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 260, height: baseHeight + 230)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 280, height: baseHeight + 230)
    }
    
    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            HomePageNotchView(
                notchViewModel: notchViewModel,
                settings: settings,
                localTimerViewModel: localTimerViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                clipboardHistoryViewModel: clipboardHistoryViewModel,
                fileConverterViewModel: fileConverterViewModel,
                mediaAndFilesSettings: mediaAndFilesSettings,
                applicationSettings: applicationSettings,
                initialPage: homePages
            )
        )
    }
    
    @MainActor
    func makeView() -> AnyView {
        if nowPlayingViewModel.hasActiveSession {
            return AnyView(
                NowPlayingMinimalNotchView(
                    nowPlayingViewModel: nowPlayingViewModel,
                    settings: mediaAndFilesSettings
                )
            )
        }
        return AnyView(EmptyView())
    }
}
