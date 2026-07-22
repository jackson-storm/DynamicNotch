//
//  HomePageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

enum HomePages: String, CaseIterable, Hashable, Codable, Identifiable {
    case camera
    case localTimer
    case vpn
    case systemStats
    case fileConverter
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .camera: return "Camera"
        case .localTimer: return "Timer"
        case .vpn: return "VPN"
        case .systemStats: return "Stats"
        case .fileConverter: return "Converter"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .camera: return "Quickly access the camera."
        case .localTimer: return "Set a quick timer."
        case .vpn: return "Manage VPN connections."
        case .systemStats: return "Monitor system resources."
        case .fileConverter: return "Convert files to multiple formats."
        }
    }
    
    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .localTimer: return "timer"
        case .vpn: return "network.badge.shield.half.filled"
        case .systemStats: return "cpu"
        case .fileConverter: return "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }
    
    var tint: Color {
        switch self {
        case .camera: return .gray
        case .localTimer: return .orange
        case .vpn: return .blue
        case .systemStats: return .green
        case .fileConverter: return .blue
        }
    }
    
    var iconTint: Color {
        switch self {
        case .camera: return .black
        case .localTimer: return .white
        case .vpn: return .white
        case .systemStats: return .white
        case .fileConverter: return .white
        }
    }
}

struct HomePageNotchView: View {
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let localTimerViewModel: LocalTimerViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let fileConverterViewModel: FileConverterViewModel
    let mediaAndFilesSettings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    let initialPage: HomePages
    
    @State private var currentPage: HomePages?
    @State private var updateTask: Task<Void, Never>? = nil
    @State private var isWaitingForSizeUpdate = false
    @State private var isPageSettled = true
    @State private var settleTask: Task<Void, Never>? = nil
    
    init(notchViewModel: NotchViewModel, settings: HomePageSettingsStore, localTimerViewModel: LocalTimerViewModel, nowPlayingViewModel: NowPlayingViewModel, fileConverterViewModel: FileConverterViewModel, mediaAndFilesSettings: MediaAndFilesSettingsStore, applicationSettings: ApplicationSettingsStore, initialPage: HomePages) {
        self.notchViewModel = notchViewModel
        self.settings = settings
        self.localTimerViewModel = localTimerViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.fileConverterViewModel = fileConverterViewModel
        self.mediaAndFilesSettings = mediaAndFilesSettings
        self.applicationSettings = applicationSettings
        self.initialPage = initialPage
        
        let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        let pageToSelect = activePages.contains(initialPage) ? initialPage : (activePages.first ?? .camera)
        self._currentPage = State(initialValue: pageToSelect)
    }
    
    var body: some View {
        let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        let settled = isPageSettled
        
        VStack() {
            if settings.homePageScrollAxis != .vertical {
                Spacer()
            }

            ScrollView(settings.homePageScrollAxis == .vertical ? .vertical : .horizontal, showsIndicators: false) {
                if settings.homePageScrollAxis == .vertical {
                    LazyVStack(spacing: 20) {
                        ForEach(activePages) { page in
                            pageView(for: page)
                                .containerRelativeFrame(.vertical)
                                .scrollTransition(.interactive) { content, phase in
                                    content
                                        .blur(radius: settled ? min(20, CGFloat(abs(phase.value)) * 150) : 20)
                                        .opacity(settled ? max(0.7, 1.0 - (abs(phase.value) * 2.0)) : 0.7)
                                }
                                .id(page)
                        }
                    }
                    .scrollTargetLayout()
                    
                } else {
                    LazyHStack(spacing: 20) {
                        ForEach(activePages) { page in
                            pageView(for: page)
                                .containerRelativeFrame(.horizontal)
                                .scrollTransition(.interactive) { content, phase in
                                    content
                                        .blur(radius: settled ? min(20, CGFloat(abs(phase.value)) * 150) : 20)
                                        .opacity(settled ? max(0.7, 1.0 - (abs(phase.value) * 2.0)) : 0.7)
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
                    let cornerRadius: CGFloat = 20
                    
                    if totalHeight > 0 {
                        let fadeStart = baseHeight / totalHeight
                        let fadeEnd = min(1.0, (baseHeight + 4) / totalHeight)
                        
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
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, isDynamicIsland ? 8 : 33)
        .padding(.bottom, isDynamicIsland ? 9 : 10)
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
            
            isPageSettled = false
            settleTask?.cancel()
            settleTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.5)) {
                    isPageSettled = true
                }
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
                            fileConverterViewModel: fileConverterViewModel,
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
                        fileConverterViewModel: fileConverterViewModel,
                        mediaAndFilesSettings: mediaAndFilesSettings,
                        applicationSettings: applicationSettings
                    )
                )
            )
            settleTask?.cancel()
            updateTask?.cancel()
        }
    }
    
    @ViewBuilder
    private func pageView(for page: HomePages) -> some View {
        switch page {
        case .camera:
            CameraNotchView(notchViewModel: notchViewModel, settings: settings, localTimerViewModel: localTimerViewModel, nowPlayingViewModel: nowPlayingViewModel, fileConverterViewModel: fileConverterViewModel, mediaAndFilesSettings: mediaAndFilesSettings, applicationSettings: applicationSettings)
        case .localTimer:
            LocalTimerSetupNotchView(localTimerViewModel: localTimerViewModel)
        case .vpn:
            VpnPageNotchView(notchViewModel: notchViewModel)
        case .systemStats:
            SystemStatsPageNotchView(notchViewModel: notchViewModel)
        case .fileConverter:
            FileConverterHomePageView(
                fileConverterViewModel: fileConverterViewModel,
                onRequestCollapse: {
                    notchViewModel.handleOutsideClick()
                }
            )
        }
    }
}
