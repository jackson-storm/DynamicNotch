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
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .camera: return "Camera"
        case .localTimer: return "Timer"
        case .vpn: return "VPN"
        case .systemStats: return "Stats"
        }
    }
    
    var subtitle: LocalizedStringKey {
        switch self {
        case .camera: return "Quickly access the camera."
        case .localTimer: return "Set a quick timer."
        case .vpn: return "Manage VPN connections."
        case .systemStats: return "Monitor system resources."
        }
    }
    
    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .localTimer: return "timer"
        case .vpn: return "network.badge.shield.half.filled"
        case .systemStats: return "cpu"
        }
    }
    
    var tint: Color {
        switch self {
        case .camera: return .black
        case .localTimer: return .orange
        case .vpn: return .blue
        case .systemStats: return .purple
        }
    }
}

struct HomePageNotchView: View {
    @Environment(\.isDynamicIsland) var isDynamicIsland
    
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let localTimerViewModel: LocalTimerViewModel
    let initialPage: HomePages
    
    @State private var currentPage: HomePages?
    @State private var updateTask: Task<Void, Never>? = nil
    @State private var isWaitingForSizeUpdate = false
    
    init(notchViewModel: NotchViewModel, settings: HomePageSettingsStore, localTimerViewModel: LocalTimerViewModel, initialPage: HomePages) {
        self.notchViewModel = notchViewModel
        self.settings = settings
        self.localTimerViewModel = localTimerViewModel
        self.initialPage = initialPage
        
        let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        let pageToSelect = activePages.contains(initialPage) ? initialPage : (activePages.first ?? .camera)
        self._currentPage = State(initialValue: pageToSelect)
    }
    
    var body: some View {
        let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        let isWaiting = isWaitingForSizeUpdate
        
        VStack(spacing: 8) {
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(activePages) { page in
                        pageView(for: page)
                            .containerRelativeFrame(.horizontal)
                            .scrollTransition(.interactive) { content, phase in
                                content
                                    .blur(radius: (!phase.isIdentity || isWaiting) ? 20 : 0)
                                    .opacity((!phase.isIdentity || isWaiting) ? 0.7 : 1.0)
                            }
                            .id(page)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage)
        }
        .clipShape(RoundedRectangle(cornerRadius: isDynamicIsland ? 24 : 28))
        .padding(.horizontal, isDynamicIsland ? 6 : 30)
        .padding(.bottom, isDynamicIsland ? 6 : 7)
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
                            localTimerViewModel: localTimerViewModel
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
                        localTimerViewModel: localTimerViewModel
                    )
                )
            )
        }
    }
    
    @ViewBuilder
    private func pageView(for page: HomePages) -> some View {
        switch page {
        case .camera:
            CameraNotchView(notchViewModel: notchViewModel, settings: settings, localTimerViewModel: localTimerViewModel)
        case .localTimer:
            LocalTimerSetupNotchView(localTimerViewModel: localTimerViewModel)
        case .vpn:
            VpnPageNotchView(notchViewModel: notchViewModel)
        case .systemStats:
            SystemStatsPageNotchView(notchViewModel: notchViewModel)
        }
    }
}
