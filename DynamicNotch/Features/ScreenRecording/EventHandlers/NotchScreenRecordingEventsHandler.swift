//
//  NotchScreenRecordingEventsHandler.swift
//  DynamicNotch
//

import SwiftUI

@MainActor
final class NotchScreenRecordingEventsHandler {
    private let notchViewModel: NotchViewModel
    private let screenRecordingViewModel: ScreenRecordingViewModel
    private let settingsViewModel: SettingsViewModel
    private let screenshotHandler: NotchScreenshotEventsHandler

    init(
        notchViewModel: NotchViewModel,
        screenRecordingViewModel: ScreenRecordingViewModel,
        settingsViewModel: SettingsViewModel,
        screenshotHandler: NotchScreenshotEventsHandler
    ) {
        self.notchViewModel = notchViewModel
        self.screenRecordingViewModel = screenRecordingViewModel
        self.settingsViewModel = settingsViewModel
        self.screenshotHandler = screenshotHandler
    }

    func handleScreenRecordingEvent(_ event: ScreenRecordingEvent) {
        guard settingsViewModel.isLiveActivityEnabled(.screenRecording) else {
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.ScreenRecording.active.id))
            return
        }

        switch event {
        case .started:
            notchViewModel.send(
                .showLiveActivity(
                    ScreenRecordingContent(
                        screenRecordingViewModel: screenRecordingViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.ScreenRecording.active.id))
            screenshotHandler.handleScreenRecordingStopped()
        }
    }
}
