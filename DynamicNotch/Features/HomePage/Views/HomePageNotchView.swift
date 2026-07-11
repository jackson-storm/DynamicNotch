//
//  HomePageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

enum HomePages: String, CaseIterable, Hashable, Codable, Identifiable {
    case camera
    case mediaPlayer
    case localTimer
    case vpn
    case systemStats

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .camera: return "Camera"
        case .mediaPlayer: return "Player"
        case .localTimer: return "Timer"
        case .vpn: return "VPN"
        case .systemStats: return "Stats"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .camera: return "Quickly access the camera."
        case .mediaPlayer: return "Control playback, even after a long pause."
        case .localTimer: return "Set a quick timer."
        case .vpn: return "Manage VPN connections."
        case .systemStats: return "Monitor system resources."
        }
    }

    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .mediaPlayer: return "music.note"
        case .localTimer: return "timer"
        case .vpn: return "network.badge.shield.half.filled"
        case .systemStats: return "cpu"
        }
    }

    var tint: Color {
        switch self {
        case .camera: return .black
        case .mediaPlayer: return .pink
        case .localTimer: return .orange
        case .vpn: return .blue
        case .systemStats: return .green
        }
    }
}

struct HomePageNotchView: View {
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let localTimerViewModel: LocalTimerViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let mediaAndFilesSettings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    let initialPage: HomePages

    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @State private var currentPage: HomePages?
    
    @State private var lastSettledPage: HomePages
    @State private var lastTargetPageFrom: HomePages? = nil
    @State private var lastTargetPageTo: HomePages? = nil
    @State private var lastProgress: CGFloat = -1.0
    @State private var programmaticTransitionProgress: CGFloat = 0.0
    @State private var isProgrammaticSwitching = false
    @State private var isPageTransitioning = false

    init(notchViewModel: NotchViewModel, settings: HomePageSettingsStore, localTimerViewModel: LocalTimerViewModel, nowPlayingViewModel: NowPlayingViewModel, mediaAndFilesSettings: MediaAndFilesSettingsStore, applicationSettings: ApplicationSettingsStore, initialPage: HomePages) {
        self.notchViewModel = notchViewModel
        self.settings = settings
        self.localTimerViewModel = localTimerViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.mediaAndFilesSettings = mediaAndFilesSettings
        self.applicationSettings = applicationSettings
        self.initialPage = initialPage
        
        let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        let pageToSelect = activePages.contains(initialPage) ? initialPage : (activePages.first ?? .camera)
        self._currentPage = State(initialValue: pageToSelect)
        self._lastSettledPage = State(initialValue: pageToSelect)
    }
    
    var body: some View {
        let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        
        VStack() {
            if settings.homePageScrollAxis != .vertical {
                Spacer()
            }

            ScrollView(settings.homePageScrollAxis == .vertical ? .vertical : .horizontal, showsIndicators: false) {
                if settings.homePageScrollAxis == .vertical {
                    LazyVStack(spacing: 0) {
                        ForEach(activePages) { page in
                            pageView(for: page)
                                .containerRelativeFrame(.vertical)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: HomePageScrollOffsetPreferenceKey.self,
                                                value: [page: geo.frame(in: .named("homePageScroll"))]
                                            )
                                    }
                                )
                                .scrollTransition(.interactive) { content, phase in
                                    content
                                        .blur(radius: blurRadius(for: page, phaseValue: phase.value, isPageTransitioning: isPageTransitioning, lastSettledPage: lastSettledPage))
                                        .opacity(1.0 - (abs(phase.value) * 0.4))
                                }
                                .id(page)
                        }
                    }
                    .scrollTargetLayout()
                    
                } else {
                    LazyHStack(spacing: 0) {
                        ForEach(activePages) { page in
                            pageView(for: page)
                                .containerRelativeFrame(.horizontal)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: HomePageScrollOffsetPreferenceKey.self,
                                                value: [page: geo.frame(in: .named("homePageScroll"))]
                                            )
                                    }
                                )
                                .scrollTransition(.interactive) { content, phase in
                                    content
                                        .blur(radius: blurRadius(for: page, phaseValue: phase.value, isPageTransitioning: isPageTransitioning, lastSettledPage: lastSettledPage))
                                        .opacity(1.0 - (abs(phase.value) * 0.4))
                                }
                                .id(page)
                        }
                    }
                    .scrollTargetLayout()
                }
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage)
            .coordinateSpace(name: "homePageScroll")
            .blur(radius: isProgrammaticSwitching ? (1.0 - abs(programmaticTransitionProgress - 0.5) * 2) * 20 : 0)
            .opacity(isProgrammaticSwitching ? Double(abs(programmaticTransitionProgress - 0.5) * 2) : 1.0)
            .mask {
                if settings.homePageScrollAxis == .vertical {
                    let totalHeight = notchViewModel.presentedNotchSize.height
                    let baseHeight = notchViewModel.notchModel.baseHeight
                    let cornerRadius: CGFloat = isDynamicIsland ? 24 : 28
                    
                    if totalHeight > 0 {
                        let fadeStart = baseHeight / totalHeight
                        let fadeEnd = min(1.0, (baseHeight + 8) / totalHeight)
                        
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .clear, location: fadeStart),
                                        .init(color: .black, location: fadeEnd),
                                        .init(color: .black, location: 1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                    }
                } else {
                    Color.black
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isDynamicIsland ? 24 : 28))
        .padding(.horizontal, initialPage == .mediaPlayer ? 0 : (isDynamicIsland ? 6 : 30))
        .padding(.bottom, initialPage == .mediaPlayer ? 0 : (isDynamicIsland ? 6 : 7))
        .contentShape(Rectangle())
        .onPreferenceChange(HomePageScrollOffsetPreferenceKey.self) { frames in
            handleScrollFrames(frames, activePages: activePages)
        }
        .onChange(of: initialPage) { _, newPage in
            if newPage != currentPage && activePages.contains(newPage) {
                currentPage = newPage
            }
        }
        .onChange(of: activePages) { _, newActivePages in
            if let current = currentPage, !newActivePages.contains(current) {
                if let first = newActivePages.first {
                    currentPage = first
                }
            }
        }
        .onDisappear {
            let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
            notchViewModel.send(
                .showLiveActivity(
                    HomePageNotchContent(
                        notchViewModel: notchViewModel,
                        settings: settings,
                        homePages: activePages.first ?? .camera,
                        localTimerViewModel: localTimerViewModel,
                        nowPlayingViewModel: nowPlayingViewModel,
                        mediaAndFilesSettings: mediaAndFilesSettings,
                        applicationSettings: applicationSettings
                    )
                )
            )
        }
    }
    
    @ViewBuilder
    private func pageView(for page: HomePages) -> some View {
        switch page {
        case .camera:
            CameraNotchView(notchViewModel: notchViewModel, settings: settings, localTimerViewModel: localTimerViewModel, nowPlayingViewModel: nowPlayingViewModel, mediaAndFilesSettings: mediaAndFilesSettings, applicationSettings: applicationSettings)
        case .mediaPlayer:
            NowPlayingExpandedNotchView(
                nowPlayingViewModel: nowPlayingViewModel,
                settings: mediaAndFilesSettings,
                applicationSettings: applicationSettings,
                onOpenPlaybackSource: { [notchViewModel] in
                    notchViewModel.handleOutsideClick()
                }
            )
        case .localTimer:
            LocalTimerSetupNotchView(localTimerViewModel: localTimerViewModel)
        case .vpn:
            VpnPageNotchView(notchViewModel: notchViewModel)
        case .systemStats:
            SystemStatsPageNotchView(notchViewModel: notchViewModel)
        }
    }
    
    private func handleScrollFrames(_ frames: [HomePages: CGRect], activePages: [HomePages]) {
        guard !frames.isEmpty else { return }
        
        for (page, frame) in frames {
            let offset = settings.homePageScrollAxis == .vertical ? frame.minY : frame.minX
            if abs(offset) < 2.0 {
                lastSettledPage = page
                if isPageTransitioning {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPageTransitioning = false
                    }
                }
                break
            }
        }
        var transitionTargetPage = lastSettledPage
        var transitionProgress: CGFloat = 0.0
        
        if let currentFrame = frames[lastSettledPage] {
            let offset = settings.homePageScrollAxis == .vertical ? currentFrame.minY : currentFrame.minX
            let size = settings.homePageScrollAxis == .vertical ? currentFrame.height : currentFrame.width
            
            if size > 0 {
                let progress = min(max(abs(offset) / size, 0.0), 1.0)
                
                if abs(offset) >= 2.0 {
                    if !isPageTransitioning {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isPageTransitioning = true
                        }
                    }
                }
                
                if offset < -1.0 {
                    if let index = activePages.firstIndex(of: lastSettledPage), index + 1 < activePages.count {
                        transitionTargetPage = activePages[index + 1]
                        transitionProgress = progress
                    }
                } else if offset > 1.0 {
                    if let index = activePages.firstIndex(of: lastSettledPage), index - 1 >= 0 {
                        transitionTargetPage = activePages[index - 1]
                        transitionProgress = progress
                    }
                }
            }
        }
        
        let hasPageChanged = lastTargetPageFrom != lastSettledPage || lastTargetPageTo != transitionTargetPage
        let hasProgressChanged = abs(lastProgress - transitionProgress) > 0.005
        
        if hasPageChanged || hasProgressChanged {
            lastTargetPageFrom = lastSettledPage
            lastTargetPageTo = transitionTargetPage
            lastProgress = transitionProgress
            
            notchViewModel.send(
                .showLiveActivity(
                    HomePageNotchContent(
                        notchViewModel: notchViewModel,
                        settings: settings,
                        homePages: lastSettledPage,
                        targetPage: transitionTargetPage,
                        transitionProgress: transitionProgress,
                        localTimerViewModel: localTimerViewModel,
                        nowPlayingViewModel: nowPlayingViewModel,
                        mediaAndFilesSettings: mediaAndFilesSettings,
                        applicationSettings: applicationSettings
                    )
                )
            )
        }
    }

    nonisolated private func blurRadius(for page: HomePages, phaseValue: Double, isPageTransitioning: Bool, lastSettledPage: HomePages) -> CGFloat {
        let baseBlur = CGFloat(abs(phaseValue)) * 30
        if isPageTransitioning && page != lastSettledPage {
            return max(15, baseBlur)
        }
        return baseBlur
    }
}

struct HomePageScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [HomePages: CGRect] = [:]
    static func reduce(value: inout [HomePages: CGRect], nextValue: () -> [HomePages: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
