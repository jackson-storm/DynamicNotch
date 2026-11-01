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
    let minimumExpandedSize: CGSize
    let navigationDirection: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentPage: HomePages? {
        let pages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        return pages.contains(initialPage) ? initialPage : pages.first
    }
    
    init(notchViewModel: NotchViewModel, settings: HomePageSettingsStore, localTimerViewModel: LocalTimerViewModel, nowPlayingViewModel: NowPlayingViewModel, mediaAndFilesSettings: MediaAndFilesSettingsStore, applicationSettings: ApplicationSettingsStore, initialPage: HomePages, minimumExpandedSize: CGSize = .zero, navigationDirection: Int = 1) {
        self.notchViewModel = notchViewModel
        self.settings = settings
        self.localTimerViewModel = localTimerViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.mediaAndFilesSettings = mediaAndFilesSettings
        self.applicationSettings = applicationSettings
        self.initialPage = initialPage
        self.minimumExpandedSize = minimumExpandedSize
        self.navigationDirection = navigationDirection
    }
    
    var body: some View {
        let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        
        ZStack(alignment: .bottom) {
            if let page = currentPage, activePages.contains(page) {
                pageView(for: page)
                    .padding(.top, [.screenshots, .calculator, .sound].contains(page) ? notchViewModel.notchModel.baseHeight + 6 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .id(page)
                    .transition(reduceMotion ? .opacity : .push(from: navigationDirection >= 0 ? .bottom : .top))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .animation(.easeInOut(duration: reduceMotion ? 0.12 : 0.24), value: currentPage)
        .background(HomePageScrollInput { direction, minimumSize in
            guard notchViewModel.isDisplayingExpandedLiveActivity,
                  let content = notchViewModel.displayedContent as? HomePageNotchContent,
                  let index = activePages.firstIndex(of: content.homePages) else { return }
            let next = index + direction
            if activePages.indices.contains(next) {
                selectPage(activePages[next], activePages: activePages, minimumSize: minimumSize)
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }
        })
        .onAppear {
            updateLastPageStatus(page: currentPage, activePages: activePages)
            // A new expansion starts at its natural size; navigation may have
            // kept the previous expansion larger to avoid ejecting the pointer.
            if (minimumExpandedSize != .zero || !activePages.contains(initialPage)), let currentPage {
                selectPage(currentPage, activePages: activePages)
            }
        }
        .onChange(of: initialPage) { _, page in
            updateLastPageStatus(page: page, activePages: activePages)
        }
        .onChange(of: activePages) { _, pages in
            if pages.contains(initialPage) {
                updateLastPageStatus(page: initialPage, activePages: pages)
            } else if let first = pages.first {
                selectPage(first, activePages: pages)
            }
        }
        .onDisappear {
            notchViewModel.isHomePageOnLastPage = false
        }
    }

    private func selectPage(_ page: HomePages, activePages: [HomePages], minimumSize: CGSize = .zero) {
        guard activePages.contains(page) else { return }
        updateLastPageStatus(page: page, activePages: activePages)
        notchViewModel.send(.showLiveActivity(HomePageNotchContent(
            notchViewModel: notchViewModel, settings: settings, homePages: page,
            localTimerViewModel: localTimerViewModel, nowPlayingViewModel: nowPlayingViewModel,
            mediaAndFilesSettings: mediaAndFilesSettings, applicationSettings: applicationSettings,
            minimumExpandedSize: minimumSize,
            navigationDirection: (activePages.firstIndex(of: page) ?? 0) >= (activePages.firstIndex(of: currentPage ?? page) ?? 0) ? 1 : -1
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
