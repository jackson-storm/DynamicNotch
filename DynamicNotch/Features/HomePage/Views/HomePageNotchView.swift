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
    case pomodoro
    case vpn
    case systemStats
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .camera: return "Camera"
        case .localTimer: return "Stopwatch"
        case .pomodoro: return "Pomodoro"
        case .vpn: return "VPN"
        case .systemStats: return "Stats"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .camera: return "Quickly access the camera."
        case .localTimer: return "Measure elapsed time."
        case .pomodoro: return "Alternate focus and break sessions."
        case .vpn: return "Manage VPN connections."
        case .systemStats: return "Monitor system resources."
        }
    }
    
    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .localTimer: return "stopwatch.fill"
        case .pomodoro: return "tomato.fill"
        case .vpn: return "network.badge.shield.half.filled"
        case .systemStats: return "cpu"
        }
    }
    
    var tint: Color {
        switch self {
        case .camera: return .gray
        case .localTimer: return .orange
        case .pomodoro: return .red
        case .vpn: return .blue
        case .systemStats: return .green
        }
    }
    
    var iconTint: Color {
        switch self {
        case .camera: return .black
        case .localTimer: return .white
        case .pomodoro: return .white
        case .vpn: return .white
        case .systemStats: return .white
        }
    }
}

struct HomePageNotchView: View {
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let stopwatchViewModel: StopwatchViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let fileConverterViewModel: FileConverterViewModel
    let mediaAndFilesSettings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    let initialPage: HomePages
    @StateObject private var pomodoroViewModel = PomodoroViewModel.shared
    
    @State private var currentPage: HomePages
    @State private var updateTask: Task<Void, Never>? = nil
    @State private var isWaitingForSizeUpdate = false
    @State private var isPageSettled = true
    @State private var settleTask: Task<Void, Never>? = nil
    
    init(notchViewModel: NotchViewModel, settings: HomePageSettingsStore, stopwatchViewModel: StopwatchViewModel, nowPlayingViewModel: NowPlayingViewModel, fileConverterViewModel: FileConverterViewModel, mediaAndFilesSettings: MediaAndFilesSettingsStore, applicationSettings: ApplicationSettingsStore, initialPage: HomePages) {
        self.notchViewModel = notchViewModel
        self.settings = settings
        self.stopwatchViewModel = stopwatchViewModel
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
        
        VStack() {
            if settings.homePageScrollAxis != .vertical {
                Spacer()
            }

            pageView(for: currentPage)
                .id(currentPage)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: isPageSettled ? 0 : 8)
                .opacity(isPageSettled ? 1 : 0.72)
                .background {
                    HomeCarouselScrollMonitor(
                        axis: settings.homePageScrollAxis,
                        isEnabled: activePages.count > 1,
                        onNext: { movePage(by: 1, through: activePages) },
                        onPrevious: { movePage(by: -1, through: activePages) }
                    )
                }
                .mask {
                    if settings.homePageScrollAxis == .vertical {
                        verticalPageMask
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
            if newPage != currentPage, activePages.contains(newPage) {
                currentPage = newPage
            }
        }
        .onChange(of: activePages) { _, newActivePages in
            if !newActivePages.contains(currentPage), let first = newActivePages.first {
                currentPage = first
            }
        }
        .onChange(of: currentPage) { oldPage, newPage in
            guard newPage != oldPage else { return }
            
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
                            stopwatchViewModel: stopwatchViewModel,
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
            settleTask?.cancel()
            updateTask?.cancel()
        }
    }

    private var verticalPageMask: some View {
        let totalHeight = notchViewModel.presentedNotchSize.height
        let baseHeight = notchViewModel.notchModel.baseHeight
        let fadeStart = totalHeight > 0 ? baseHeight / totalHeight : 0
        let fadeEnd = totalHeight > 0 ? min(1.0, (baseHeight + 4) / totalHeight) : 0

        return RoundedRectangle(cornerRadius: 20)
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
    }

    private func movePage(by offset: Int, through pages: [HomePages]) {
        guard pages.count > 1 else { return }
        let currentIndex = pages.firstIndex(of: currentPage) ?? 0
        let nextIndex = (currentIndex + offset + pages.count) % pages.count

        withAnimation(.easeInOut(duration: 0.18)) {
            currentPage = pages[nextIndex]
        }
    }
    
    @ViewBuilder
    private func pageView(for page: HomePages) -> some View {
        switch page {
        case .camera:
            CameraNotchView(notchViewModel: notchViewModel, settings: settings, stopwatchViewModel: stopwatchViewModel, nowPlayingViewModel: nowPlayingViewModel, fileConverterViewModel: fileConverterViewModel, mediaAndFilesSettings: mediaAndFilesSettings, applicationSettings: applicationSettings)
        case .localTimer:
            StopwatchSetupNotchView(stopwatchViewModel: stopwatchViewModel)
        case .pomodoro:
            PomodoroSetupNotchView(
                viewModel: pomodoroViewModel,
                notchViewModel: notchViewModel,
                stopwatchViewModel: stopwatchViewModel
            )
        case .vpn:
            VpnPageNotchView(notchViewModel: notchViewModel)
        case .systemStats:
            SystemStatsPageNotchView(notchViewModel: notchViewModel)
        }
    }
}
