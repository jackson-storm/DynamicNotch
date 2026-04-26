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
    private let networkViewModel: NetworkViewModel
    private let downloadViewModel: DownloadViewModel
    private let settingsViewModel: SettingsViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private let fileTrayViewModel: FileTrayViewModel
    private let timerViewModel: TimerViewModel
    private let lockScreenManager: LockScreenManager
    private let systemHandler: NotchSystemEventsHandler
    private let focusHandler: NotchFocusEventsHandler
    private let hudHandler: NotchHUDEventsHandler
    private let connectivityHandler: NotchConnectivityEventsHandler
    private let powerHandler: NotchPowerEventsHandler
    private let mediaHandler: NotchMediaEventsHandler
    private let timerHandler: NotchTimerEventsHandler
    private var cancellables = Set<AnyCancellable>()
    
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
        networkViewModel: NetworkViewModel,
        downloadViewModel: DownloadViewModel,
        airDropViewModel: AirDropNotchViewModel,
        fileTrayViewModel: FileTrayViewModel,
        settingsViewModel: SettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        timerViewModel: TimerViewModel,
        lockScreenManager: LockScreenManager
    ) {
        self.notchViewModel = notchViewModel
        self.networkViewModel = networkViewModel
        self.downloadViewModel = downloadViewModel
        self.settingsViewModel = settingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.fileTrayViewModel = fileTrayViewModel
        self.timerViewModel = timerViewModel
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
            networkViewModel: networkViewModel,
            settingsViewModel: settingsViewModel
        )
        self.powerHandler = NotchPowerEventsHandler(
            notchViewModel: notchViewModel,
            powerService: powerService,
            settingsViewModel: settingsViewModel
        )
        self.mediaHandler = NotchMediaEventsHandler(
            notchViewModel: notchViewModel,
            downloadViewModel: downloadViewModel,
            airDropViewModel: airDropViewModel,
            settingsViewModel: settingsViewModel,
            nowPlayingViewModel: nowPlayingViewModel
        )
        self.timerHandler = NotchTimerEventsHandler(
            notchViewModel: notchViewModel,
            timerViewModel: timerViewModel,
            settingsViewModel: settingsViewModel
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
                    TrayActiveNotchContent(fileTrayViewModel: fileTrayViewModel)
                )
            )
        }

        observeSettingsChanges()
    }
    
    func checkFirstLaunch() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        if !hasSeenOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.handleOnboardingEvent(.onboarding)
            }
        } else if nowPlayingViewModel.hasActiveSession &&
                    settingsViewModel.isLiveActivityEnabled(.nowPlaying) {
            mediaHandler.handleNowPlaying(.started)
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

        if markAsSeen &&
            nowPlayingViewModel.hasActiveSession &&
            settingsViewModel.isLiveActivityEnabled(.nowPlaying) {
            mediaHandler.handleNowPlaying(.started)
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
    
    func handleNetworkEvent(_ event: NetworkEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        connectivityHandler.handleNetwork(event)
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        powerHandler.handle(event)
    }

    func handleDownloadEvent(_ event: DownloadEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        mediaHandler.handleDownload(event)
    }

    func handleAirDropEvent(_ event: AirDropEvent) {
        guard !isLockScreenTransitionActive else { return }

        mediaHandler.handleAirDrop(event)
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

    func handleLockScreenEvent(_ event: LockScreenEvent) {
        guard settingsViewModel.isLiveActivityEnabled(.lockScreen) else {
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.LockScreen.activity.id))
            return
        }

        switch event {
        case .started:
            notchViewModel.send(
                .showLiveActivity(
                    LockScreenNotchContent(
                        lockScreenManager: lockScreenManager,
                        style: settingsViewModel.lockScreen.lockScreenStyle
                    )
                )
            )
            
        case .stopped:
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
                TrayActiveNotchContent(fileTrayViewModel: fileTrayViewModel)
            )
        )
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
                    if self.networkViewModel.hotspotActive {
                        self.connectivityHandler.handleNetwork(.hotspotActive)
                    }
                } else {
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Network.hotspot.id))
                }
            }
            .store(in: &cancellables)

        settingsViewModel.connectivity.$hotspotAppearanceStyle
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.settingsViewModel.connectivity.isHotspotLiveActivityEnabled else { return }
                guard self.networkViewModel.hotspotActive else { return }

                self.connectivityHandler.handleNetwork(.hotspotActive)
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
                        self.mediaHandler.handleDownload(.started)
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
                    self.mediaHandler.refreshDragAndDropPresentation()
                    self.syncFileTrayLiveActivity()
                } else {
                    NotchContentRegistry.DragAndDrop.liveActivityIDs.forEach { id in
                        self.notchViewModel.send(.hideLiveActivity(id: id))
                    }
                    self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.DragAndDrop.trayActive.id))
                }
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$dragAndDropActivityMode
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.mediaHandler.refreshDragAndDropPresentation()
                self?.syncFileTrayLiveActivity()
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

        settingsViewModel.mediaAndFiles.$isDropMotionAnimationEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.mediaHandler.refreshDragAndDropPresentation()
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
    }
}
