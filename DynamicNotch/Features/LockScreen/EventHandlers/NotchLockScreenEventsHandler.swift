//
//  NotchLockScreenEventsHandler.swift
//  DynamicNotch
//

import SwiftUI

@MainActor
final class NotchLockScreenEventsHandler {
    private let notchViewModel: NotchViewModel
    private let lockScreenManager: LockScreenManager
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        lockScreenManager: LockScreenManager,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.lockScreenManager = lockScreenManager
        self.settingsViewModel = settingsViewModel
    }

    func handleLockScreenEvent(_ event: LockScreenEvent) {
        switch event {
        case .started:
            notchViewModel.isLocked = true
            guard settingsViewModel.isLiveActivityEnabled(.lockScreen) else {
                notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.LockScreen.activity.id))
                return
            }
            notchViewModel.send(
                .showLiveActivity(
                    LockScreenNotchContent(
                        lockScreenManager: lockScreenManager,
                        style: settingsViewModel.lockScreen.lockScreenStyle
                    )
                )
            )

        case .stopped:
            notchViewModel.isLocked = false
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.LockScreen.activity.id))
        }
    }
}
