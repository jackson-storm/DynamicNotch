//
//  NotchScreenshotEventsHandler.swift
//  DynamicNotch
//

import SwiftUI
import Combine

@MainActor
final class NotchScreenshotEventsHandler {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel
    let screenshotViewModel: ScreenshotViewModel
    let screenRecordingResultViewModel: ScreenRecordingResultViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel,
        screenshotViewModel: ScreenshotViewModel,
        screenRecordingResultViewModel: ScreenRecordingResultViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
        self.screenshotViewModel = screenshotViewModel
        self.screenRecordingResultViewModel = screenRecordingResultViewModel
        
        setupScreenshotCallbacks()
        setupScreenRecordingResultCallbacks()
        setupCaptureMonitoring()
        setupDiskSaveObserver()
    }
    
    private func setupScreenshotCallbacks() {
        screenshotViewModel.onScreenshotReady = { [weak self] screenshot in
            guard let self else { return }
            guard self.settingsViewModel.screenRecording.isScreenshotActivityEnabled else { return }
            
            ScreenshotFlyAnimationService.shared.playFlyToNotchAnimation(image: screenshot.image) { [weak self] in
                guard let self else { return }
                let content = ScreenshotNotchContent(viewModel: self.screenshotViewModel)
                if self.settingsViewModel.screenRecording.isScreenshotAutoHideEnabled {
                    let duration = TimeInterval(self.settingsViewModel.screenRecording.screenshotTemporaryActivityDuration)
                    self.notchViewModel.send(.showTemporaryNotification(content, duration: duration))
                } else {
                    self.notchViewModel.send(.showLiveActivity(content))
                }
            }
        }
        
        screenshotViewModel.onScreenshotDismissed = { [weak self] in
            guard let self else { return }
            self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Screenshot.active.id))
            self.notchViewModel.hideTemporaryNotification()
        }
    }
    
    private func setupScreenRecordingResultCallbacks() {
        screenshotViewModel.onScreenRecordingCaptured = { [weak self] fileURL, thumbnail, fileName in
            guard let self else { return }
            guard self.settingsViewModel.isLiveActivityEnabled(.screenRecording) else { return }

            self.screenRecordingResultViewModel.setRecordingResult(
                fileURL: fileURL,
                thumbnail: thumbnail,
                fileName: fileName
            )
        }

        screenRecordingResultViewModel.onResultReady = { [weak self] _ in
            guard let self else { return }
            guard self.settingsViewModel.isLiveActivityEnabled(.screenRecording) else { return }

            let content = ScreenRecordingResultNotchContent(viewModel: self.screenRecordingResultViewModel)
            if self.settingsViewModel.screenRecording.isScreenshotAutoHideEnabled {
                let duration = TimeInterval(self.settingsViewModel.screenRecording.screenshotTemporaryActivityDuration)
                self.notchViewModel.send(.showTemporaryNotification(content, duration: duration))
            } else {
                self.notchViewModel.send(.showLiveActivity(content))
            }
        }

        screenRecordingResultViewModel.onResultDismissed = { [weak self] in
            guard let self else { return }
            self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.ScreenRecording.result.id))
            self.notchViewModel.hideTemporaryNotification()
        }
    }
    
    private func setupCaptureMonitoring() {
        let isCaptureMonitoringNeeded = settingsViewModel.screenRecording.isScreenshotActivityEnabled ||
            settingsViewModel.isLiveActivityEnabled(.screenRecording)
        if isCaptureMonitoringNeeded {
            screenshotViewModel.startMonitoring(
                disableSystemThumbnail: settingsViewModel.screenRecording.isScreenshotActivityEnabled
            )
        } else {
            ScreenshotMonitorService.setSystemFloatingThumbnailEnabled(true)
        }
        
        Publishers.CombineLatest(
            settingsViewModel.screenRecording.$isScreenshotActivityEnabled,
            settingsViewModel.screenRecording.$isScreenRecordingLiveActivityEnabled
        )
        .removeDuplicates { $0 == $1 }
        .sink { [weak self] isScreenshotEnabled, isScreenRecordingEnabled in
            guard let self else { return }
            if isScreenshotEnabled || isScreenRecordingEnabled {
                self.screenshotViewModel.startMonitoring(disableSystemThumbnail: isScreenshotEnabled)
            } else {
                self.screenshotViewModel.stopMonitoring()
                ScreenshotMonitorService.setSystemFloatingThumbnailEnabled(true)
            }
        }
        .store(in: &cancellables)
    }
    
    private func setupDiskSaveObserver() {
        notchViewModel.$notchModel
            .map { model in
                model.temporaryNotificationContent?.id == NotchContentRegistry.Screenshot.active.id ||
                model.liveActivityContent?.id == NotchContentRegistry.Screenshot.active.id
            }
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] isShowingScreenshot in
                if !isShowingScreenshot {
                    self?.screenshotViewModel.saveToDiskIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    func handleScreenRecordingStopped() {
        screenshotViewModel.scanNow()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.screenshotViewModel.scanNow()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.screenshotViewModel.scanNow()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.screenshotViewModel.scanNow()
        }
    }
}
