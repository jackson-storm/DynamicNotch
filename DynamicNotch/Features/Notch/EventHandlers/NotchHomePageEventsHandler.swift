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

    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel,
        localTimerViewModel: LocalTimerViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
        self.localTimerViewModel = localTimerViewModel
    }

    func handleHomePage(_ event: HomePageEvent) {
        switch event {
        case .homePageOn:
            notchViewModel.send(.showLiveActivity(HomePageNotchContent(notchViewModel: notchViewModel, homePages: .camera, localTimerViewModel: localTimerViewModel)))
            
        case .homePageOff:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.active.id))
        }
    }
}
