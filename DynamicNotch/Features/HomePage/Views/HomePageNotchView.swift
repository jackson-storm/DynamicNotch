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
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let localTimerViewModel: LocalTimerViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let mediaAndFilesSettings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    let initialPage: HomePages

    @State private var currentPage: HomePages?
    @State private var updateTask: Task<Void, Never>? = nil
    @State private var isWaitingForSizeUpdate = false

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
    }
    
    var body: some View {
        let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        let isWaiting = isWaitingForSizeUpdate
        
        VStack() {
            if settings.homePageScrollAxis != .vertical && currentPage != .mediaPlayer {
                Spacer()
            }

            ScrollView(settings.homePageScrollAxis == .vertical ? .vertical : .horizontal, showsIndicators: false) {
                if settings.homePageScrollAxis == .vertical {
                    LazyVStack(spacing: 0) {
                        ForEach(activePages) { page in
                            pageView(for: page)
                                .containerRelativeFrame(.vertical)
                                .scrollTransition(.interactive) { content, phase in
                                    content
                                        .blur(radius: isWaiting ? 20 : CGFloat(abs(phase.value)) * 20)
                                        .opacity(isWaiting ? 0.7 : 1.0 - (abs(phase.value) * 0.3))
                                        .scaleEffect(CGFloat(1.0 - (abs(phase.value) * 0.30)))
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
                                .scrollTransition(.interactive) { content, phase in
                                    content
                                        .blur(radius: isWaiting ? 20 : CGFloat(abs(phase.value)) * 20)
                                        .opacity(isWaiting ? 0.7 : 1.0 - (abs(phase.value) * 0.3))
                                        .scaleEffect(CGFloat(1.0 - (abs(phase.value) * 0.30)))
                                }
                                .id(page)
                        }
                    }
                    .scrollTargetLayout()
                }
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage)
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
        // The media player page reuses the standalone player, which brings its own
        // insets — drop the container's so it lands exactly like the auto player.
        .padding(.horizontal, currentPage == .mediaPlayer ? 0 : (isDynamicIsland ? 6 : 30))
        .padding(.bottom, currentPage == .mediaPlayer ? 0 : (isDynamicIsland ? 6 : 7))
        .contentShape(Rectangle())
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
        .onChange(of: currentPage) { oldPage, newPage in
            guard let newPage = newPage, newPage != oldPage else { return }
            
            withAnimation(.easeInOut(duration: 0.15)) {
                isWaitingForSizeUpdate = true
            }
            
            updateTask?.cancel()
            updateTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                
                notchViewModel.send(
                    .showLiveActivity(
                        HomePageNotchContent(
                            notchViewModel: notchViewModel,
                            settings: settings,
                            homePages: newPage,
                            localTimerViewModel: localTimerViewModel,
                            nowPlayingViewModel: nowPlayingViewModel,
                            mediaAndFilesSettings: mediaAndFilesSettings,
                            applicationSettings: applicationSettings
                        )
                    )
                )

                withAnimation(.easeInOut(duration: 0.35)) {
                    isWaitingForSizeUpdate = false
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
            // Reuse the exact auto Now Playing expanded player so the page is
            // visually identical to the transient live activity.
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
}
