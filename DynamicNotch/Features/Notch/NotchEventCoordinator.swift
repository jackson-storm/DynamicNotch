//
//  NotchEventCoordinator.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/22/26.
//

import SwiftUI
import Combine

@MainActor
final class NotchEventCoordinator: ObservableObject {
    private let notchViewModel: NotchViewModel
    private let wifiViewModel: WifiViewModel
    private let vpnViewModel: VpnViewModel
    private let downloadViewModel: DownloadViewModel
    private let settingsViewModel: SettingsViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private let fileTrayViewModel: FileTrayViewModel
    private let fileConverterViewModel: FileConverterViewModel
    private let timerViewModel: TimerViewModel
    private let localTimerViewModel: LocalTimerViewModel
    private let homePageViewModel: HomePageViewModel
    private let calendarViewModel: CalendarViewModel
    private let lockScreenManager: LockScreenManager
    private let systemHandler: NotchSystemEventsHandler
    private let focusHandler: NotchFocusEventsHandler
    private let hudHandler: NotchHUDEventsHandler
    private let connectivityHandler: NotchConnectivityEventsHandler
    private let powerHandler: NotchPowerEventsHandler
    private let mediaHandler: NotchMediaEventsHandler
    private let downloadHandler: NotchDownloadEventsHandler
    private let dragAndDropHandler: NotchDragAndDropEventsHandler
    private let timerHandler: NotchTimerEventsHandler
    private let homePageHandler: NotchHomePageEventsHandler
    private let localTimerHandler: NotchLocalTimerEventsHandler
    private let calendarHandler: NotchCalendarEventsHandler
    private var cancellables = Set<AnyCancellable>()
    private var fileConverterExpansionTask: Task<Void, Never>?
    
    private var isOnboardingActive: Bool {
        OnboardingSteps.contains(id: notchViewModel.notchModel.liveActivityContent?.id) ||
        OnboardingSteps.contains(id: notchViewModel.notchModel.temporaryNotificationContent?.id) ||
        {
            #if DEBUG
            OnboardingSteps.containsDebug(id: notchViewModel.notchModel.liveActivityContent?.id) ||
            OnboardingSteps.containsDebug(id: notchViewModel.notchModel.temporaryNotificationContent?.id)
            #else
            false
            #endif
        }()
    }

    private var isLockScreenTransitionActive: Bool {
        lockScreenManager.isTransitioning ||
        notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.LockScreen.activity.id
    }
    
    init (
        notchViewModel: NotchViewModel,
        bluetoothViewModel: BluetoothViewModel,
        powerService: PowerService,
        wifiViewModel: WifiViewModel,
        vpnViewModel: VpnViewModel,
        downloadViewModel: DownloadViewModel,
        airDropViewModel: AirDropNotchViewModel,
        fileTrayViewModel: FileTrayViewModel,
        fileConverterViewModel: FileConverterViewModel,
        settingsViewModel: SettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        timerViewModel: TimerViewModel,
        lockScreenManager: LockScreenManager,
        homePageViewModel: HomePageViewModel,
        localTimerViewModel: LocalTimerViewModel,
        calendarViewModel: CalendarViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.wifiViewModel = wifiViewModel
        self.vpnViewModel = vpnViewModel
        self.downloadViewModel = downloadViewModel
        self.settingsViewModel = settingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.fileTrayViewModel = fileTrayViewModel
        self.fileConverterViewModel = fileConverterViewModel
        self.timerViewModel = timerViewModel
        self.localTimerViewModel = localTimerViewModel
        self.homePageViewModel = homePageViewModel
        self.calendarViewModel = calendarViewModel
        self.lockScreenManager = lockScreenManager
        self.systemHandler = NotchSystemEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        self.focusHandler = NotchFocusEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        self.hudHandler = NotchHUDEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel
        )
        self.connectivityHandler = NotchConnectivityEventsHandler(
            notchViewModel: notchViewModel,
            bluetoothViewModel: bluetoothViewModel,
            wifiViewModel: wifiViewModel,
            vpnViewModel: vpnViewModel,
            settingsViewModel: settingsViewModel
        )
        self.powerHandler = NotchPowerEventsHandler(
            notchViewModel: notchViewModel,
            powerService: powerService,
            settingsViewModel: settingsViewModel
        )
        self.mediaHandler = NotchMediaEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: nowPlayingViewModel
        )
        self.downloadHandler = NotchDownloadEventsHandler(
            notchViewModel: notchViewModel,
            downloadViewModel: downloadViewModel,
            settingsViewModel: settingsViewModel
        )
        self.dragAndDropHandler = NotchDragAndDropEventsHandler(
            notchViewModel: notchViewModel,
            airDropViewModel: airDropViewModel,
            settingsViewModel: settingsViewModel
        )
        self.timerHandler = NotchTimerEventsHandler(
            notchViewModel: notchViewModel,
            timerViewModel: timerViewModel,
            settingsViewModel: settingsViewModel,
            localTimerViewModel: localTimerViewModel
        )
        self.homePageHandler = NotchHomePageEventsHandler(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            localTimerViewModel: localTimerViewModel,
            nowPlayingViewModel: nowPlayingViewModel
        )
        self.calendarHandler = NotchCalendarEventsHandler(
            notchViewModel: notchViewModel,
            calendarViewModel: calendarViewModel,
            settingsViewModel: settingsViewModel
        )
        self.localTimerHandler = NotchLocalTimerEventsHandler(
            notchViewModel: notchViewModel,
            localTimerViewModel: localTimerViewModel,
            timerViewModel: timerViewModel
        )
        self.fileTrayViewModel.onItemsChange = { [weak notchViewModel, weak settingsViewModel, weak fileTrayViewModel] items in
            guard let notchViewModel, let settingsViewModel, let fileTrayViewModel else {
                return
            }

            let hasTrayItems = items.isEmpty == false

            guard settingsViewModel.isLiveActivityEnabled(.drop),
                  settingsViewModel.mediaAndFiles.isTrayLiveActivityEnabled,
                  hasTrayItems else {
                notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.trayActive.id))
                return
            }

            notchViewModel.send(
                .showLiveActivity(
                    TrayActiveNotchContent(
                        fileTrayViewModel: fileTrayViewModel,
                        mediaSettings: settingsViewModel.mediaAndFiles
                    )
                )
            )
        }
        self.fileConverterViewModel.onItemChange = { [weak self] item in
            guard let self else {
                return
            }

            guard self.settingsViewModel.isLiveActivityEnabled(.drop),
                  self.settingsViewModel.mediaAndFiles.isFileConverterLiveActivityEnabled,
                  !self.fileConverterViewModel.isConverted,
                  item != nil else {
                self.fileConverterExpansionTask?.cancel()
                self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.fileConverterActive.id))
                return
            }

            self.notchViewModel.send(.showLiveActivity(self.makeFileConverterActiveContent()))
            self.scheduleFileConverterExpansion()
        }

        observeCalendarEvents()
        observeSettingsChanges()
    }
    
    func checkFirstLaunch() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        if !hasSeenOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.handleOnboardingEvent(.onboarding)
            }
        } else {
            if nowPlayingViewModel.hasActiveSession &&
                settingsViewModel.isLiveActivityEnabled(.nowPlaying) {
                mediaHandler.handleNowPlaying(.started)
            }
            if settingsViewModel.isLiveActivityEnabled(.homePage) {
                homePageHandler.handleHomePage(.homePageOn)
            }
        }
    }
    
    func hideOnboarding(markAsSeen: Bool = false) {
        if markAsSeen {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        }
        
        OnboardingSteps.allCases.forEach { step in
            notchViewModel.send(.hideLiveActivity(id: step.liveActivityID))
        }
        
        #if DEBUG
        OnboardingSteps.allCases.forEach { step in
            notchViewModel.send(.hideLiveActivity(id: step.debugLiveActivityID))
        }
        #endif

        if markAsSeen {
            if nowPlayingViewModel.hasActiveSession &&
                settingsViewModel.isLiveActivityEnabled(.nowPlaying) {
                mediaHandler.handleNowPlaying(.started)
            }
            if settingsViewModel.isLiveActivityEnabled(.homePage) {
                homePageHandler.handleHomePage(.homePageOn)
            }
        }
    }
    
    func finishOnboarding() {
        hideOnboarding(markAsSeen: true)
    }
    
    func showOnboarding(step: OnboardingSteps = .first) {
        notchViewModel.send(
            .showLiveActivity(
                OnboardingNotchContent(
                    step: step,
                    notchEventCoordinator: self
                )
            )
        )
    }
    
    #if DEBUG
    func showDebugOnboardingPreview(step: OnboardingSteps = .first) {
        notchViewModel.send(
            .showLiveActivity(
                DebugOnboardingPreviewNotchContent(
                    step: step,
                    notchEventCoordinator: self
                )
            )
        )
    }
    #endif
    
    func handleNotchWidthEvent(_ event: NotchSizeEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }
        guard settingsViewModel.isTemporaryActivityEnabled(.notchSize) else { return }

        systemHandler.handleNotchSize(event)
    }
    
    func handleFocusEvent(_ event: FocusEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        focusHandler.handleFocus(event)
    }
    
    func handleHudEvent(_ event: HudEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        hudHandler.handleHud(event)
    }
    
    func handleOnboardingEvent(_ event: OnboardingEvent) {
        switch event {
        case .onboarding:
            showOnboarding()
        }
    }
    
    func handleBluetoothEvent(_ event: BluetoothEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        connectivityHandler.handleBluetooth(event)
    }
    
    func handleWifiEvent(_ event: WifiEvent) {
        guard !isLockScreenTransitionActive else { return }
        if event != .noInternetConnection {
            guard !isOnboardingActive else { return }
        }

        connectivityHandler.handleWifi(event)
        wifiViewModel.wifiEvent = nil
    }

    func handleVpnEvent(_ event: VpnEvent) {
        guard !isLockScreenTransitionActive else { return }
        guard !isOnboardingActive else { return }

        connectivityHandler.handleVpn(event)
        vpnViewModel.vpnEvent = nil
    }

    @discardableResult
    func requestInternetAccess() -> Bool {
        guard wifiViewModel.isInternetAvailable else {
            handleWifiEvent(.noInternetConnection)
            return false
        }

        return true
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        powerHandler.handle(event)
    }

    func handleDownloadEvent(_ event: DownloadEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        downloadHandler.handleDownload(event)
    }

    func handleAirDropEvent(_ event: AirDropEvent) {
        guard !isLockScreenTransitionActive else { return }

        dragAndDropHandler.handleAirDrop(event)
    }
    
    func handleNowPlayingEvent(_ event: NowPlayingEvent) {
        guard !isOnboardingActive else { return }

        mediaHandler.handleNowPlaying(event)
    }

    func handleTimerEvent(_ event: TimerEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        timerHandler.handleTimer(event)
    }
    
    func handleHomePageEvent(_ event: HomePageEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }
        
        homePageHandler.handleHomePage(event)
    }

    func handleScreenRecordingEvent(_ event: ScreenRecordingEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }
        guard settingsViewModel.isLiveActivityEnabled(.screenRecording) else {
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.ScreenRecording.active.id))
            return
        }

        switch event {
        case .started:
            notchViewModel.send(
                .showLiveActivity(
                    ScreenRecordingContent(settingsViewModel: settingsViewModel)
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.ScreenRecording.active.id))
        }
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

    private func syncFileTrayLiveActivity(hasItems: Bool? = nil) {
        let hasTrayItems = hasItems ?? fileTrayViewModel.items.isEmpty == false

        guard settingsViewModel.isLiveActivityEnabled(.drop),
              settingsViewModel.mediaAndFiles.isTrayLiveActivityEnabled,
              hasTrayItems else {
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.trayActive.id))
            return
        }

        notchViewModel.send(
            .showLiveActivity(
                TrayActiveNotchContent(
                    fileTrayViewModel: fileTrayViewModel,
                    mediaSettings: settingsViewModel.mediaAndFiles
                )
            )
        )
    }

    private func syncFileConverterLiveActivity(hasItem: Bool? = nil) {
        let hasConverterItem = hasItem ?? fileConverterViewModel.hasItem

        guard settingsViewModel.isLiveActivityEnabled(.drop),
              settingsViewModel.mediaAndFiles.isFileConverterLiveActivityEnabled,
              !fileConverterViewModel.isConverted,
              hasConverterItem else {
            fileConverterExpansionTask?.cancel()
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.fileConverterActive.id))
            return
        }

        notchViewModel.send(.showLiveActivity(makeFileConverterActiveContent()))
    }

    private func makeFileConverterActiveContent() -> FileConverterActiveNotchContent {
        FileConverterActiveNotchContent(
            fileConverterViewModel: fileConverterViewModel,
            mediaSettings: settingsViewModel.mediaAndFiles,
            onRequestCollapse: { [weak notchViewModel] in
                notchViewModel?.handleOutsideClick()
            }
        )
    }

    private func scheduleFileConverterExpansion() {
        fileConverterExpansionTask?.cancel()
        fileConverterExpansionTask = Task { [weak self] in
            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled else { return }

                let didFinish = await MainActor.run { [weak self] in
                    self?.expandFileConverterIfReady() ?? true
                }

                if didFinish {
                    return
                }
            }

            await MainActor.run { [weak self] in
                self?.fileConverterExpansionTask = nil
            }
        }
    }

    @discardableResult
    private func expandFileConverterIfReady() -> Bool {
        guard fileConverterViewModel.hasItem,
              !fileConverterViewModel.isConverted else {
            fileConverterExpansionTask = nil
            return true
        }

        guard notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.DragAndDrop.fileConverterActive.id,
              notchViewModel.notchModel.temporaryNotificationContent == nil else {
            return false
        }

        guard !notchViewModel.notchModel.isLiveActivityExpanded else {
            fileConverterExpansionTask = nil
            return true
        }

        guard notchViewModel.canExpandActiveLiveActivity else {
            return false
        }

        notchViewModel.expandActiveLiveActivity()
        fileConverterExpansionTask = nil
        return true
    }
    
    private func observeCalendarEvents() {
        calendarViewModel.$events
            .map { _ in self.calendarViewModel.hasUpcomingEvent }
            .removeDuplicates()
            .sink { [weak self] hasUpcoming in
                self?.calendarHandler.handleCalendarEvent(hasUpcoming)
            }
            .store(in: &cancellables)
            
        settingsViewModel.calendar.$isCalendarLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }
                self.calendarHandler.handleCalendarEvent(isEnabled && self.calendarViewModel.hasUpcomingEvent)
            }
            .store(in: &cancellables)

        settingsViewModel.application.$isCloseAtFocusLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                self.calendarHandler.handleCalendarEvent(self.calendarViewModel.hasUpcomingEvent)
            }
            .store(in: &cancellables)
    }

    private func observeSettingsChanges() {
        settingsViewModel.connectivity.$isFocusLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled == false {
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Focus.active.id))
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
                    self.syncFileTrayLiveActivity()
                    self.syncFileConverterLiveActivity()
                } else {
                    NotchContentRegistry.DragAndDrop.liveActivityIDs.forEach { id in
                        self.notchViewModel.send(.hideLiveActivity(id: id))
                    }
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.trayActive.id))
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.fileConverterActive.id))
                }
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$dragAndDropActivityMode
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.dragAndDropHandler.refreshDragAndDropPresentation()
                self?.syncFileTrayLiveActivity()
                self?.syncFileConverterLiveActivity()
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$dragAndDropTargetColorStyle
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.dragAndDropHandler.refreshDragAndDropPresentation()
                self?.syncFileConverterLiveActivity()
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isTrayLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    self.syncFileTrayLiveActivity()
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
                    self.syncFileConverterLiveActivity()
                } else {
                    self.notchViewModel.send(
                        .hideLiveActivity(id: NotchContentRegistry.DragAndDrop.fileConverterActive.id)
                    )
                }
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isDropMotionAnimationEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.dragAndDropHandler.refreshDragAndDropPresentation()
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

        settingsViewModel.screenRecording.$isScreenRecordingLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled == false {
                    self.notchViewModel.send(
                        .hideLiveActivity(id: NotchContentRegistry.ScreenRecording.active.id)
                    )
                }
            }
            .store(in: &cancellables)

        notchViewModel.$notchModel
            .map(\.isLiveActivityExpanded)
            .removeDuplicates()
            .sink { [weak self] isExpanded in
                self?.mediaHandler.handleExpansionChange(isExpanded: isExpanded)
            }
            .store(in: &cancellables)

        settingsViewModel.lockScreen.$isLockScreenLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.lockScreenManager.isLocked {
                        self.handleLockScreenEvent(.started)
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
                guard let self else { return }
                self.showLanguageChangedNotification(for: language)
            }
            .store(in: &cancellables)
    }

    private func showLanguageChangedNotification(for language: DynamicNotchLanguage) {
        let content = LanguageChangedNotchContent(language: language)
        notchViewModel.send(.showTemporaryNotification(content, duration: 3.0))
    }
}
