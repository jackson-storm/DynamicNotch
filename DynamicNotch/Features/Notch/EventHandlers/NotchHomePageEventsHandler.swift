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
    private let stopwatchViewModel: StopwatchViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private let fileConverterViewModel: FileConverterViewModel

    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel,
        stopwatchViewModel: StopwatchViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        fileConverterViewModel: FileConverterViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
        self.stopwatchViewModel = stopwatchViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.fileConverterViewModel = fileConverterViewModel
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
                stopwatchViewModel: stopwatchViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                fileConverterViewModel: fileConverterViewModel,
                mediaAndFilesSettings: settingsViewModel.mediaAndFiles,
                applicationSettings: settingsViewModel.application
            )))
            
        case .homePageOff:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.active.id))
        }
    }
}
