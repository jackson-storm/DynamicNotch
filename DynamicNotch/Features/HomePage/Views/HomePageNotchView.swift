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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentPage: HomePages? {
        let pages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        return pages.contains(initialPage) ? initialPage : pages.first
    }
    
    init(notchViewModel: NotchViewModel, settings: HomePageSettingsStore, localTimerViewModel: LocalTimerViewModel, nowPlayingViewModel: NowPlayingViewModel, mediaAndFilesSettings: MediaAndFilesSettingsStore, applicationSettings: ApplicationSettingsStore, initialPage: HomePages, minimumExpandedSize: CGSize = .zero) {
        self.notchViewModel = notchViewModel
        self.settings = settings
        self.localTimerViewModel = localTimerViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.mediaAndFilesSettings = mediaAndFilesSettings
        self.applicationSettings = applicationSettings
        self.initialPage = initialPage
        self.minimumExpandedSize = minimumExpandedSize
    }
    
    var body: some View {
        let activePages = settings.homePageOrder.filter { !settings.homePageDisabled.contains($0) }
        
        let pageHeights = activePages.map { pageHeight(for: $0) }
        let offsets = pageHeights.reduce(into: [CGFloat(0)]) { result, height in
            result.append((result.last ?? 0) + height + 20)
        }
        let selectedIndex = currentPage.flatMap { activePages.firstIndex(of: $0) } ?? 0
        let position = offsets[selectedIndex]
        let visiblePageHeight = currentPage.map { pageHeight(for: $0) } ?? 0

        GeometryReader { viewport in
            ZStack(alignment: .top) {
                ForEach(Array(activePages.enumerated()), id: \.element) { index, page in
                    pageView(for: page)
                        .padding(.top, [.screenshots, .calculator, .sound].contains(page) ? notchViewModel.notchModel.baseHeight + 6 : 0)
                        .frame(height: pageHeights[index], alignment: .bottom)
                        .modifier(HomePageScrollMotion(
                            origin: offsets[index], height: pageHeights[index],
                            position: position, reduceMotion: reduceMotion
                        ))
                        .allowsHitTesting(page == currentPage)
                        .accessibilityHidden(page != currentPage)
                }
            }
            .frame(width: viewport.size.width, height: viewport.size.height, alignment: .top)
            .clipped()
            .mask(alignment: .top) {
                // A hover safety floor can leave spare black space below a
                // short card; the next page must not appear there at rest.
                Rectangle()
                    .frame(height: visiblePageHeight)
                    .animation(nil, value: visiblePageHeight)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85), value: currentPage)
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

    private func pageHeight(for page: HomePages) -> CGFloat {
        let content = HomePageNotchContent.pageContent(for: page)
        let model = notchViewModel.notchModel
        let size = notchViewModel.isDynamicIsland
            ? content.expandedDynamicIslandSize(baseWidth: model.baseWidth, baseHeight: model.baseHeight)
            : content.expandedSize(baseWidth: model.baseWidth, baseHeight: model.baseHeight)
        return size.height
    }

    private func selectPage(_ page: HomePages, activePages: [HomePages], minimumSize: CGSize = .zero) {
        guard activePages.contains(page) else { return }
        updateLastPageStatus(page: page, activePages: activePages)
        notchViewModel.send(.showLiveActivity(HomePageNotchContent(
            notchViewModel: notchViewModel, settings: settings, homePages: page,
            localTimerViewModel: localTimerViewModel, nowPlayingViewModel: nowPlayingViewModel,
            mediaAndFilesSettings: mediaAndFilesSettings, applicationSettings: applicationSettings,
            minimumExpandedSize: minimumSize
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
            CameraNotchView(notchViewModel: notchViewModel, settings: settings, localTimerViewModel: localTimerViewModel, nowPlayingViewModel: nowPlayingViewModel, mediaAndFilesSettings: mediaAndFilesSettings, applicationSettings: applicationSettings, isActive: currentPage == .camera)
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
