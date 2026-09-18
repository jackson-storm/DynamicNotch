//
//  NotchHomePageEventsHandler.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import SwiftUI

enum HomePageEvent: Equatable {
    case homePageOn
    case homePageOff
}

@MainActor
final class NotchHomePageEventsHandler {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel
    private let localTimerViewModel: LocalTimerViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private let fileConverterViewModel: FileConverterViewModel

    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel,
        localTimerViewModel: LocalTimerViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        fileConverterViewModel: FileConverterViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
        self.localTimerViewModel = localTimerViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.fileConverterViewModel = fileConverterViewModel
    }
    
    func handleHomePage(_ event: HomePageEvent) {
        switch event {
        case .homePageOn:
            notchViewModel.send(.showLiveActivity(makeHomePageContent()))
            
        case .homePageOff:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.active.id))
        }
    }

    func showToolNotch() {
        notchViewModel.showForegroundContent(makeHomePageContent(), expanded: true)
    }

    var canShowToolNotch: Bool {
        settingsViewModel.homePage.isHomePageLiveActivityEnabled &&
        activePages.isEmpty == false
    }

    private var activePages: [HomePages] {
        settingsViewModel.homePage.homePageOrder.filter {
            !settingsViewModel.homePage.homePageDisabled.contains($0)
        }
    }

    private func makeHomePageContent() -> HomePageNotchContent {
        HomePageNotchContent(
            notchViewModel: notchViewModel,
            settings: settingsViewModel.homePage,
            homePages: activePages.first ?? .camera,
            localTimerViewModel: localTimerViewModel,
            nowPlayingViewModel: nowPlayingViewModel,
            fileConverterViewModel: fileConverterViewModel,
            mediaAndFilesSettings: settingsViewModel.mediaAndFiles,
            applicationSettings: settingsViewModel.application
        )
    }
}
