import SwiftUI
internal import EventKit

struct HomePageNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.HomePage.active.id
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let homePages: HomePages
    let targetPage: HomePages
    let transitionProgress: CGFloat
    let localTimerViewModel: LocalTimerViewModel
    let nowPlayingViewModel: NowPlayingViewModel
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

    var isTransitioning: Bool {
        transitionProgress > 0.001 && transitionProgress < 0.999
    }

    init(
        notchViewModel: NotchViewModel,
        settings: HomePageSettingsStore,
        homePages: HomePages,
        targetPage: HomePages? = nil,
        transitionProgress: CGFloat = 0.0,
        localTimerViewModel: LocalTimerViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        mediaAndFilesSettings: MediaAndFilesSettingsStore,
        applicationSettings: ApplicationSettingsStore
    ) {
        self.notchViewModel = notchViewModel
        self.settings = settings
        self.homePages = homePages
        self.targetPage = targetPage ?? homePages
        self.transitionProgress = transitionProgress
        self.localTimerViewModel = localTimerViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.mediaAndFilesSettings = mediaAndFilesSettings
        self.applicationSettings = applicationSettings
    }
    
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        let radFrom = staticExpandedCornerRadius(for: homePages, baseRadius: baseRadius)
        let radTo = staticExpandedCornerRadius(for: targetPage, baseRadius: baseRadius)
        
        return (
            top: radFrom.top + (radTo.top - radFrom.top) * transitionProgress,
            bottom: radFrom.bottom + (radTo.bottom - radFrom.bottom) * transitionProgress
        )
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
        let radFrom = staticExpandedDynamicIslandCornerRadius(for: homePages, baseHeight: baseHeight)
        let radTo = staticExpandedDynamicIslandCornerRadius(for: targetPage, baseHeight: baseHeight)
        return radFrom + (radTo - radFrom) * transitionProgress
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let sizeFrom = staticExpandedSize(for: homePages, baseWidth: baseWidth, baseHeight: baseHeight)
        let sizeTo = staticExpandedSize(for: targetPage, baseWidth: baseWidth, baseHeight: baseHeight)
        
        return CGSize(
            width: sizeFrom.width + (sizeTo.width - sizeFrom.width) * transitionProgress,
            height: sizeFrom.height + (sizeTo.height - sizeFrom.height) * transitionProgress
        )
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let sizeFrom = staticExpandedDynamicIslandSize(for: homePages, baseWidth: baseWidth, baseHeight: baseHeight)
        let sizeTo = staticExpandedDynamicIslandSize(for: targetPage, baseWidth: baseWidth, baseHeight: baseHeight)
        
        return CGSize(
            width: sizeFrom.width + (sizeTo.width - sizeFrom.width) * transitionProgress,
            height: sizeFrom.height + (sizeTo.height - sizeFrom.height) * transitionProgress
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
                initialPage: homePages
            )
        )
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}

// MARK: - Static Size Helpers for Interpolation
private extension HomePageNotchContent {
    func staticExpandedCornerRadius(for page: HomePages, baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        switch page {
        case .camera:
            let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
            return (top: isStarted ? 34 : 24, bottom: isStarted ? 48 : 38)
            
        case .mediaPlayer:
            return (top: 34, bottom: 44)

        case .localTimer, .vpn, .systemStats:
            return (top: 24, bottom: 38)
        }
    }
    
    func staticExpandedDynamicIslandCornerRadius(for page: HomePages, baseHeight: CGFloat) -> CGFloat {
        switch page {
        case .camera:
            let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
            let isLarge = UserDefaults.standard.bool(forKey: "isCameraLarge")
            
            if !isStarted {
                return baseHeight * 0.2
            }
            if isLarge {
                return baseHeight * 0.15
            } else {
                return baseHeight * 0.2
            }
            
        case .mediaPlayer, .localTimer, .vpn, .systemStats:
            return baseHeight * 0.2
        }
    }
    
    func staticExpandedSize(for page: HomePages, baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch page {
        case .camera:
            let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
            let isLarge = UserDefaults.standard.bool(forKey: "isCameraLarge")
            
            if !isStarted {
                return .init(width: baseWidth + 65, height: baseHeight + 125)
            }
            if isLarge {
                return .init(width: baseWidth + 250, height: baseHeight + 220)
            } else {
                return .init(width: baseWidth + 180, height: baseHeight + 180)
            }
            
        case .mediaPlayer:
            return .init(width: baseWidth + 200, height: baseHeight + 160)

        case .localTimer:
            return .init(width: baseWidth + 100, height: baseHeight + 125)

        case .vpn:
            return .init(width: baseWidth + 140, height: baseHeight + 110)

        case .systemStats:
            return .init(width: baseWidth + 140, height: baseHeight + 110)
        }
    }
    
    func staticExpandedDynamicIslandSize(for page: HomePages, baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch page {
        case .camera:
            let isStarted = UserDefaults.standard.bool(forKey: "isCameraStarted")
            let isLarge = UserDefaults.standard.bool(forKey: "isCameraLarge")
            
            if !isStarted {
                return .init(width: baseWidth + 95, height: baseHeight + 125)
            }
            if isLarge {
                return .init(width: baseWidth + 280, height: baseHeight + 220)
            } else {
                return .init(width: baseWidth + 210, height: baseHeight + 180)
            }
            
        case .mediaPlayer:
            return .init(width: baseWidth + 220, height: baseHeight + 160)

        case .localTimer:
            return .init(width: baseWidth + 140, height: baseHeight + 125)

        case .vpn:
            return .init(width: baseWidth + 180, height: baseHeight + 105)

        case .systemStats:
            return .init(width: baseWidth + 180, height: baseHeight + 110)
        }
    }
}
