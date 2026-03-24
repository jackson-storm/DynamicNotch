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
    private let bluetoothViewModel: BluetoothViewModel
    private let powerService: PowerService
    private let networkViewModel: NetworkViewModel
    private let downloadViewModel: DownloadViewModel
    private let airDropViewModel: AirDropNotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private let lockScreenManager: LockScreenManager
    private var cancellables = Set<AnyCancellable>()
    private var deferredNowPlayingHideWhileExpanded = false
    
    private var isOnboardingActive: Bool {
        notchViewModel.notchModel.liveActivityContent?.id == "onboarding" ||
        notchViewModel.notchModel.temporaryNotificationContent?.id == "onboarding"
    }
    
    private var isOnboardingPending: Bool {
        !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }

    private var isLockScreenTransitionActive: Bool {
        lockScreenManager.isTransitioning ||
        notchViewModel.notchModel.liveActivityContent?.id == "lockScreen"
    }

    private var isExpandedNowPlayingVisible: Bool {
        notchViewModel.notchModel.liveActivityContent?.id == "nowPlaying" &&
        notchViewModel.notchModel.isLiveActivityExpanded
    }
    
    init (
        notchViewModel: NotchViewModel,
        bluetoothViewModel: BluetoothViewModel,
        powerService: PowerService,
        networkViewModel: NetworkViewModel,
        downloadViewModel: DownloadViewModel,
        airDropViewModel: AirDropNotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel,
        lockScreenManager: LockScreenManager
    ) {
        self.notchViewModel = notchViewModel
        self.bluetoothViewModel = bluetoothViewModel
        self.powerService = powerService
        self.networkViewModel = networkViewModel
        self.downloadViewModel = downloadViewModel
        self.airDropViewModel = airDropViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        self.lockScreenManager = lockScreenManager
        observeSettingsChanges()
    }
    
    func checkFirstLaunch() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        if !hasSeenOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.handleOnboardingEvent(.onboarding)
            }
        } else if nowPlayingViewModel.hasActiveSession &&
                    generalSettingsViewModel.isLiveActivityEnabled(.nowPlaying) {
            notchViewModel.send(.showLiveActivity(NowPlayingNotchContent(nowPlayingViewModel: nowPlayingViewModel)))
        }
    }
    
    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        notchViewModel.send(.hideLiveActivity(id: "onboarding"))

        if nowPlayingViewModel.hasActiveSession &&
            generalSettingsViewModel.isLiveActivityEnabled(.nowPlaying) {
            notchViewModel.send(.showLiveActivity(NowPlayingNotchContent(nowPlayingViewModel: nowPlayingViewModel)))
        }
    }
    
    func handleNotchWidthEvent(_ event: NotchSizeEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }
        guard generalSettingsViewModel.isTemporaryActivityEnabled(.notchSize) else { return }
        
        switch event {
        case .width:
            notchViewModel.send(.showTemporaryNotification(NotchSizeWidthNotchContent(generalSettingsViewModel: generalSettingsViewModel), duration: 2))
            
        case .height:
            notchViewModel.send(.showTemporaryNotification(NotchSizeHeightNotchContent(generalSettingsViewModel: generalSettingsViewModel), duration: 2))
        }
    }
    
    func handleFocusEvent(_ event: FocusEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }
        
        switch event {
        case .FocusOn:
            guard generalSettingsViewModel.isLiveActivityEnabled(.focus) else { return }
            notchViewModel.send(.showLiveActivity(FocusOnNotchContent()))
            
        case .FocusOff:
            notchViewModel.send(.hideLiveActivity(id: "focus.on"))
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.focusOff) else { return }
            self.notchViewModel.send(.showTemporaryNotification(FocusOffNotchContent(), duration: 3))
        }
    }
    
    func handleHudEvent(_ event: HudEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }
        
        switch event {
        case .display(let level):
            guard generalSettingsViewModel.isHUDEnabled(.brightness) else { return }
            notchViewModel.send(.showTemporaryNotification(HudNotchContent(kind: .brightness, level: level), duration: 2))
            
        case .keyboard(let level):
            guard generalSettingsViewModel.isHUDEnabled(.keyboard) else { return }
            notchViewModel.send(.showTemporaryNotification(HudNotchContent(kind: .keyboard, level: level), duration: 2))
            
        case .volume(let level):
            guard generalSettingsViewModel.isHUDEnabled(.volume) else { return }
            notchViewModel.send(.showTemporaryNotification(HudNotchContent(kind: .volume, level: level), duration: 2))
        }
    }
    
    func handleOnboardingEvent(_ event: OnboardingEvent) {
        switch event {
        case .onboarding:
            notchViewModel.send(.showLiveActivity(OnboardingNotchContent(notchEventCoordinator: self)))
        }
    }
    
    func handleBluetoothEvent(_ event: BluetoothEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }
        
        switch event {
        case .connected:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.bluetooth) else { return }
            notchViewModel.send(.showTemporaryNotification(BluetoothConnectedNotchContent(bluetoothViewModel: bluetoothViewModel), duration: 5))
        }
    }
    
    func handleNetworkEvent(_ event: NetworkEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }
        
        switch event {
        case .wifiConnected:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.wifi) else { return }
            notchViewModel.send(.showTemporaryNotification(WifiConnectedNotchContent(), duration: 3))
            
        case .vpnConnected:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.vpn) else { return }
            notchViewModel.send(.showTemporaryNotification(VpnConnectedNotchContent(networkViewModel: networkViewModel), duration: 5))
            
        case .hotspotActive:
            guard generalSettingsViewModel.isLiveActivityEnabled(.hotspot) else { return }
            notchViewModel.send(.showLiveActivity(HotspotActiveContent()))
            
        case .hotspotHide:
            notchViewModel.send(.hideLiveActivity(id: "hotspot.active"))
        }
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }
        
        switch event {
        case .charger:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.charger) else { return }
            notchViewModel.send(.showTemporaryNotification(ChargerNotchContent(powerService: powerService), duration: 4))
            
        case .lowPower:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.lowPower) else { return }
            notchViewModel.send(.showTemporaryNotification(LowPowerNotchContent(powerService: powerService), duration: 4))
            
        case .fullPower:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.fullPower) else { return }
            notchViewModel.send(.showTemporaryNotification(FullPowerNotchContent(powerService: powerService), duration: 4))
        }
    }

    func handleDownloadEvent(_ event: DownloadEvent) {
        guard !isOnboardingActive else { return }
        guard !isLockScreenTransitionActive else { return }

        switch event {
        case .started:
            guard generalSettingsViewModel.isLiveActivityEnabled(.downloads) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    DownloadNotchContent(downloadViewModel: downloadViewModel)
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: "download.active"))
        }
    }

    func handleAirDropEvent(_ event: AirDropEvent) {
        guard !isLockScreenTransitionActive else { return }

        switch event {
        case .dragStarted:
            notchViewModel.send(
                .showLiveActivity(
                    AirDropNotchContent(airDropViewModel: airDropViewModel)
                )
            )

        case .dragEnded, .dropped:
            notchViewModel.send(.hideLiveActivity(id: "airdrop"))
        }
    }
    
    func handleNowPlayingEvent(_ event: NowPlayingEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .started:
            deferredNowPlayingHideWhileExpanded = false
            guard generalSettingsViewModel.isLiveActivityEnabled(.nowPlaying) else { return }
            notchViewModel.send(.showLiveActivity(NowPlayingNotchContent(nowPlayingViewModel: nowPlayingViewModel)))
            
        case .stopped:
            if isExpandedNowPlayingVisible {
                deferredNowPlayingHideWhileExpanded = true
                return
            }

            deferredNowPlayingHideWhileExpanded = false
            notchViewModel.send(.hideLiveActivity(id: "nowPlaying"))
        }
    }

    func handleLockScreenEvent(_ event: LockScreenEvent) {
        guard generalSettingsViewModel.isLiveActivityEnabled(.lockScreen) else {
            notchViewModel.send(.hideLiveActivity(id: "lockScreen"))
            return
        }

        switch event {
        case .started:
            notchViewModel.send(.showLiveActivity(LockScreenNotchContent(lockScreenManager: lockScreenManager)))
            
        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: "lockScreen"))
        }
    }

    private func observeSettingsChanges() {
        generalSettingsViewModel.$isFocusLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled == false {
                    self.notchViewModel.send(.hideLiveActivity(id: "focus.on"))
                }
            }
            .store(in: &cancellables)

        generalSettingsViewModel.$isHotspotLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.networkViewModel.hotspotActive {
                        self.handleNetworkEvent(.hotspotActive)
                    }
                } else {
                    self.notchViewModel.send(.hideLiveActivity(id: "hotspot.active"))
                }
            }
            .store(in: &cancellables)

        generalSettingsViewModel.$isNowPlayingLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.nowPlayingViewModel.hasActiveSession {
                        self.handleNowPlayingEvent(.started)
                    }
                } else {
                    self.deferredNowPlayingHideWhileExpanded = false
                    self.notchViewModel.send(.hideLiveActivity(id: "nowPlaying"))
                }
            }
            .store(in: &cancellables)

        generalSettingsViewModel.$isDownloadsLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.downloadViewModel.hasActiveDownloads {
                        self.handleDownloadEvent(.started)
                    }
                } else {
                    self.notchViewModel.send(.hideLiveActivity(id: "download.active"))
                }
            }
            .store(in: &cancellables)

        notchViewModel.$notchModel
            .map(\.isLiveActivityExpanded)
            .removeDuplicates()
            .sink { [weak self] isExpanded in
                guard let self else { return }
                guard self.deferredNowPlayingHideWhileExpanded else { return }
                guard !isExpanded else { return }
                guard self.nowPlayingViewModel.hasActiveSession == false else {
                    self.deferredNowPlayingHideWhileExpanded = false
                    return
                }

                self.deferredNowPlayingHideWhileExpanded = false
                self.notchViewModel.send(.hideLiveActivity(id: "nowPlaying"))
            }
            .store(in: &cancellables)

        generalSettingsViewModel.$isLockScreenLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    if self.lockScreenManager.isLocked {
                        self.handleLockScreenEvent(.started)
                    }
                } else {
                    self.notchViewModel.send(.hideLiveActivity(id: "lockScreen"))
                }
            }
            .store(in: &cancellables)
    }
}
