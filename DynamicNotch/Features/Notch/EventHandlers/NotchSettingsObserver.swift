//
//  NotchSettingsObserver.swift
//  DynamicNotch
//

import SwiftUI
import Combine

@MainActor
final class NotchSettingsObserver {
    private let settingsViewModel: SettingsViewModel
    private let notchViewModel: NotchViewModel
    private let wifiViewModel: WifiViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private let downloadViewModel: DownloadViewModel
    private let timerViewModel: TimerViewModel
    private let localTimerViewModel: LocalTimerViewModel
    private let screenRecordingViewModel: ScreenRecordingViewModel
    private let lockScreenManager: LockScreenManager
    private let connectivityHandler: NotchConnectivityEventsHandler
    private let mediaHandler: NotchMediaEventsHandler
    private let downloadHandler: NotchDownloadEventsHandler
    private let dragAndDropHandler: NotchDragAndDropEventsHandler
    private let timerHandler: NotchTimerEventsHandler
    private let homePageHandler: NotchHomePageEventsHandler
    private let localTimerHandler: NotchLocalTimerEventsHandler
    private let lockScreenHandler: NotchLockScreenEventsHandler
    private let onLanguageChanged: (DynamicNotchLanguage) -> Void
    private var cancellables = Set<AnyCancellable>()

    init(
        settingsViewModel: SettingsViewModel,
        notchViewModel: NotchViewModel,
        wifiViewModel: WifiViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        downloadViewModel: DownloadViewModel,
        timerViewModel: TimerViewModel,
        localTimerViewModel: LocalTimerViewModel,
        screenRecordingViewModel: ScreenRecordingViewModel,
        lockScreenManager: LockScreenManager,
        connectivityHandler: NotchConnectivityEventsHandler,
        mediaHandler: NotchMediaEventsHandler,
        downloadHandler: NotchDownloadEventsHandler,
        dragAndDropHandler: NotchDragAndDropEventsHandler,
        timerHandler: NotchTimerEventsHandler,
        homePageHandler: NotchHomePageEventsHandler,
        localTimerHandler: NotchLocalTimerEventsHandler,
        lockScreenHandler: NotchLockScreenEventsHandler,
        onLanguageChanged: @escaping (DynamicNotchLanguage) -> Void
    ) {
        self.settingsViewModel = settingsViewModel
        self.notchViewModel = notchViewModel
        self.wifiViewModel = wifiViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.downloadViewModel = downloadViewModel
        self.timerViewModel = timerViewModel
        self.localTimerViewModel = localTimerViewModel
        self.screenRecordingViewModel = screenRecordingViewModel
        self.lockScreenManager = lockScreenManager
        self.connectivityHandler = connectivityHandler
        self.mediaHandler = mediaHandler
        self.downloadHandler = downloadHandler
        self.dragAndDropHandler = dragAndDropHandler
        self.timerHandler = timerHandler
        self.homePageHandler = homePageHandler
        self.localTimerHandler = localTimerHandler
        self.lockScreenHandler = lockScreenHandler
        self.onLanguageChanged = onLanguageChanged

        startObserving()
    }

    private func startObserving() {
        observeConnectivitySettings()
        observeMediaAndFilesSettings()
        observeScreenRecordingSettings()
        observeLockScreenSettings()
        observeGeneralSettings()
    }

    private func observeConnectivitySettings() {
        settingsViewModel.connectivity.$isFocusLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                if isEnabled == false {
                    self?.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Focus.active.id))
                }
            }
            .store(in: &cancellables)

        settingsViewModel.connectivity.$isHotspotLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.wifiViewModel.hotspotActive {
                        self.connectivityHandler.handleWifi(.hotspotActive)
                    }
                } else {
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Wifi.hotspot.id))
                }
            }
            .store(in: &cancellables)

        settingsViewModel.connectivity.$hotspotAppearanceStyle
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.settingsViewModel.connectivity.isHotspotLiveActivityEnabled else { return }
                guard self.wifiViewModel.hotspotActive else { return }

                self.connectivityHandler.handleWifi(.hotspotActive)
            }
            .store(in: &cancellables)
    }

    private func observeMediaAndFilesSettings() {
        settingsViewModel.mediaAndFiles.$isNowPlayingLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.nowPlayingViewModel.hasActiveSession {
                        self.mediaHandler.handleNowPlaying(.started)
                    }
                } else {
                    self.mediaHandler.cancelDeferredNowPlayingHide()
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.nowPlaying.id))
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            settingsViewModel.mediaAndFiles.$isNowPlayingPauseHideTimerEnabled.removeDuplicates(),
            settingsViewModel.mediaAndFiles.$nowPlayingPauseHideDelay.removeDuplicates()
        )
        .sink { [weak self] _, _ in
            guard let self else { return }
            guard self.settingsViewModel.isLiveActivityEnabled(.nowPlaying) else { return }
            guard self.nowPlayingViewModel.hasActiveSession else { return }

            self.mediaHandler.syncNowPlayingPlaybackState()
        }
        .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isDownloadsLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.downloadViewModel.hasActiveDownloads {
                        self.downloadHandler.handleDownload(.started)
                    }
                } else {
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.download.id))
                }
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isDragAndDropLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    self.dragAndDropHandler.refreshDragAndDropPresentation()
                    self.dragAndDropHandler.syncFileTrayLiveActivity()
                    self.dragAndDropHandler.syncFileConverterLiveActivity()
                } else {
                    self.dragAndDropHandler.hideAllDragAndDropActivities()
                }
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$dragAndDropActivityMode
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.dragAndDropHandler.refreshDragAndDropPresentation()
                self?.dragAndDropHandler.syncFileTrayLiveActivity()
                self?.dragAndDropHandler.syncFileConverterLiveActivity()
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isAirDropLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.dragAndDropHandler.refreshDragAndDropPresentation()
                self?.dragAndDropHandler.syncAirDropTransferLiveActivity()
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isTrayLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    self.dragAndDropHandler.syncFileTrayLiveActivity()
                } else {
                    self.notchViewModel.send(
                        .hideLiveActivity(id: NotchContentRegistry.DragAndDrop.trayActive.id)
                    )
                }
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isFileConverterLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    self.dragAndDropHandler.syncFileConverterLiveActivity()
                } else {
                    self.notchViewModel.send(
                        .hideLiveActivity(id: NotchContentRegistry.DragAndDrop.fileConverterActive.id)
                    )
                }
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isTimerLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.timerViewModel.snapshot != nil {
                        self.timerHandler.handleTimer(.started)
                    }
                } else {
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
                }
            }
            .store(in: &cancellables)
    }

    private func observeScreenRecordingSettings() {
        settingsViewModel.screenRecording.$isScreenRecordingLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                if isEnabled == false {
                    self?.notchViewModel.send(
                        .hideLiveActivity(id: NotchContentRegistry.ScreenRecording.active.id)
                    )
                }
            }
            .store(in: &cancellables)

        settingsViewModel.screenRecording.$screenRecordingStyle
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.screenRecordingViewModel.isRecording,
                   self.settingsViewModel.isLiveActivityEnabled(.screenRecording) {
                    self.notchViewModel.send(
                        .showLiveActivity(
                            ScreenRecordingContent(
                                screenRecordingViewModel: self.screenRecordingViewModel,
                                settingsViewModel: self.settingsViewModel
                            )
                        )
                    )
                }
            }
            .store(in: &cancellables)

        settingsViewModel.screenRecording.$isScreenRecordingDefaultStrokeEnabled
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.screenRecordingViewModel.isRecording,
                   self.settingsViewModel.isLiveActivityEnabled(.screenRecording) {
                    self.notchViewModel.send(
                        .showLiveActivity(
                            ScreenRecordingContent(
                                screenRecordingViewModel: self.screenRecordingViewModel,
                                settingsViewModel: self.settingsViewModel
                            )
                        )
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func observeLockScreenSettings() {
        settingsViewModel.lockScreen.$isLockScreenLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.lockScreenManager.isLocked {
                        self.lockScreenHandler.handleLockScreenEvent(.started)
                    }
                } else {
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.LockScreen.activity.id))
                }
            }
            .store(in: &cancellables)

        settingsViewModel.lockScreen.$lockScreenStyle
            .removeDuplicates()
            .sink { [weak self] style in
                guard let self else { return }
                guard self.notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.LockScreen.activity.id else {
                    return
                }

                self.notchViewModel.send(
                    .showLiveActivity(
                        LockScreenNotchContent(
                            lockScreenManager: self.lockScreenManager,
                            style: style
                        )
                    )
                )
            }
            .store(in: &cancellables)
    }

    private func observeGeneralSettings() {
        notchViewModel.$notchModel
            .map(\.isLiveActivityExpanded)
            .removeDuplicates()
            .sink { [weak self] isExpanded in
                self?.mediaHandler.handleExpansionChange(isExpanded: isExpanded)
            }
            .store(in: &cancellables)

        settingsViewModel.homePage.$isHomePageLiveActivityEnabled
            .sink { [weak self] isEnabled in
                if isEnabled {
                    self?.homePageHandler.handleHomePage(.homePageOn)
                } else {
                    self?.homePageHandler.handleHomePage(.homePageOff)
                }
            }
            .store(in: &cancellables)

        localTimerViewModel.$state
            .dropFirst()
            .sink { [weak self] state in
                self?.localTimerHandler.handleLocalTimerStateChanged(state)
            }
            .store(in: &cancellables)

        settingsViewModel.application.$appLanguage
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] language in
                self?.onLanguageChanged(language)
            }
            .store(in: &cancellables)
    }
}
