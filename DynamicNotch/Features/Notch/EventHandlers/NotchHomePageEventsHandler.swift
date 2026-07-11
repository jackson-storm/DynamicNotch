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

    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel,
        localTimerViewModel: LocalTimerViewModel,
        nowPlayingViewModel: NowPlayingViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
        self.localTimerViewModel = localTimerViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
    }
    
    func handleHomePage(_ event: HomePageEvent) {
        switch event {
        case .homePageOn:
            let activePages = settingsViewModel.homePage.homePageOrder.filter { !settingsViewModel.homePage.homePageDisabled.contains($0) }
            let activePage = activePages.first ?? .camera
            notchViewModel.send(.showLiveActivity(HomePageNotchContent(
                notchViewModel: notchViewModel,
                settings: settingsViewModel.homePage,
                homePages: activePage,
                localTimerViewModel: localTimerViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                mediaAndFilesSettings: settingsViewModel.mediaAndFiles,
                applicationSettings: settingsViewModel.application
            )))
            
        case .homePageOff:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.active.id))
        }
    }
}
