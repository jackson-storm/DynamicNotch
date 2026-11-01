//
//  HomePageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

struct HomePageNotchView: View {
    @EnvironmentObject private var tools: HomePageTools
    
    let notchViewModel: NotchViewModel
    let settings: HomePageSettingsStore
    let localTimerViewModel: LocalTimerViewModel
    let nowPlayingViewModel: NowPlayingViewModel
    let mediaAndFilesSettings: MediaAndFilesSettingsStore
    let applicationSettings: ApplicationSettingsStore
    let initialPage: HomePages
    
    @State private var currentPage: HomePages?
    
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
        
        ZStack(alignment: .bottom) {
            if let page = currentPage, activePages.contains(page) {
                pageView(for: page)
                    .padding(.top, [.screenshots, .calculator, .sound].contains(page) ? notchViewModel.notchModel.baseHeight + 6 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .id(page)
                    .transition(.identity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HomePageScrollInput { direction in
            guard let currentPage, let index = activePages.firstIndex(of: currentPage) else { return }
            let next = index + direction
            if activePages.indices.contains(next) {
                selectPage(activePages[next], activePages: activePages)
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            } else if next >= activePages.count {
                notchViewModel.dismissActiveContent()
            }
        })
        .onHover { notchViewModel.isHoveringScrollableContent = $0 }
        .onAppear { updateLastPageStatus(page: currentPage, activePages: activePages) }
        .onChange(of: initialPage) { _, page in
            if activePages.contains(page), page != currentPage {
                withAnimation(.easeInOut(duration: 0.18)) { currentPage = page }
                updateLastPageStatus(page: page, activePages: activePages)
            }
        }
        .onChange(of: activePages) { _, pages in
            if let currentPage, pages.contains(currentPage) {
                updateLastPageStatus(page: currentPage, activePages: pages)
            } else if let first = pages.first {
                selectPage(first, activePages: pages)
            } else { currentPage = nil }
        }
        .onDisappear {
            notchViewModel.isHomePageOnLastPage = false
            notchViewModel.isHoveringScrollableContent = false
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

    private func selectPage(_ page: HomePages, activePages: [HomePages]) {
        guard activePages.contains(page) else { return }
        withAnimation(.easeInOut(duration: 0.18)) { currentPage = page }
        updateLastPageStatus(page: page, activePages: activePages)
        guard page != initialPage else { return }
        notchViewModel.send(.showLiveActivity(HomePageNotchContent(
            notchViewModel: notchViewModel, settings: settings, homePages: page,
            localTimerViewModel: localTimerViewModel, nowPlayingViewModel: nowPlayingViewModel,
            mediaAndFilesSettings: mediaAndFilesSettings, applicationSettings: applicationSettings
        )))
    }
    
    private func updateLastPageStatus(page: HomePages?, activePages: [HomePages]) {
        let isLast = page != nil && page == activePages.last
        if notchViewModel.isHomePageOnLastPage != isLast {
            notchViewModel.isHomePageOnLastPage = isLast
        }
    }
    
    @ViewBuilder
    private func pageView(for page: HomePages) -> some View {
        switch page {
        case .camera:
            CameraNotchView(notchViewModel: notchViewModel, settings: settings, localTimerViewModel: localTimerViewModel, nowPlayingViewModel: nowPlayingViewModel, mediaAndFilesSettings: mediaAndFilesSettings, applicationSettings: applicationSettings)
        case .localTimer:
            LocalTimerSetupNotchView(localTimerViewModel: localTimerViewModel)
        case .vpn:
            VpnPageNotchView(notchViewModel: notchViewModel)
        case .screenshots:
            ScreenshotCaptureNotchView(model: tools.screenshots) { mode in
                tools.screenshots.capture(mode, screen: NSScreen.preferredNotchScreen(for: applicationSettings)) {
                    notchViewModel.dismissActiveContent()
                }
            }
        case .calculator:
            CalculatorNotchView(model: tools.calculator, isActive: currentPage == .calculator)
        case .sound:
            SoundControlNotchView(model: tools.sound, isActive: currentPage == .sound)
        }
    }
}
