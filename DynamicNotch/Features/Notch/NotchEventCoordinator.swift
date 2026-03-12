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
    private let airDropViewModel: AirDropNotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    
    private var isOnboardingActive: Bool {
        notchViewModel.notchModel.liveActivityContent?.id == "onboarding" ||
        notchViewModel.notchModel.temporaryNotificationContent?.id == "onboarding"
    }
    
    private var isOnboardingPending: Bool {
        !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    private var isAirDropActive: Bool {
        notchViewModel.notchModel.content?.id == "airdrop"
    }
    
    init (
        notchViewModel: NotchViewModel,
        bluetoothViewModel: BluetoothViewModel,
        powerService: PowerService,
        networkViewModel: NetworkViewModel,
        airDropViewModel: AirDropNotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.bluetoothViewModel = bluetoothViewModel
        self.powerService = powerService
        self.networkViewModel = networkViewModel
        self.airDropViewModel = airDropViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
    }
    
    func checkFirstLaunch() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        if !hasSeenOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.handleOnboardingEvent(.onboarding)
            }
        }
    }
    
    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        notchViewModel.send(.hideLiveActivity(id: "onboarding"))
    }
    
    func handleAirDropEvent(_ event: AirDropEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .dragStarted:
            notchViewModel.send(.showLiveActivity(AirDropNotchContent(airDropViewModel: airDropViewModel, notchViewModel: notchViewModel)))
            
        case .dragEnded:
            notchViewModel.send(.hideLiveActivity(id: "airdrop"))
            
        case .dropped(let urls, let point):
            if let view = airDropViewModel.presentationView
                ?? NSApp.keyWindow?.contentView
                ?? NSApp.mainWindow?.contentView
                ?? NSApp.windows.compactMap(\.contentView).first {
                airDropViewModel.shareViaAirDrop(urls: urls, point: point, view: view)
            }
            notchViewModel.send(.hideLiveActivity(id: "airdrop"))
        }
    }
    
    func handleNotchWidthEvent(_ event: NotchSizeEvent) {
        guard !isOnboardingActive else { return }
        guard !isOnboardingActive && !isAirDropActive else { return }
        
        switch event {
        case .width:
            notchViewModel.send(.showTemporaryNotification(NotchSizeWidthNotchContent(generalSettingsViewModel: generalSettingsViewModel), duration: 2))
            
        case .height:
            notchViewModel.send(.showTemporaryNotification(NotchSizeHeightNotchContent(generalSettingsViewModel: generalSettingsViewModel), duration: 2))
        }
    }
    
    func handleFocusEvent(_ event: FocusEvent) {
        guard !isOnboardingActive else { return }
        guard !isOnboardingActive && !isAirDropActive else { return }
        
        switch event {
        case .FocusOn:
            notchViewModel.send(.showLiveActivity(FocusOnNotchContent()))
            
        case .FocusOff:
            notchViewModel.send(.hideLiveActivity(id: "focus.on"))
            self.notchViewModel.send(.showTemporaryNotification(FocusOffNotchContent(), duration: 3))
        }
    }
    
    func handleHudEvent(_ event: HudEvent) {
        guard !isOnboardingActive else { return }
        guard !isOnboardingActive && !isAirDropActive else { return }
        
        switch event {
        case .display(let level):
            notchViewModel.send(.showTemporaryNotification(HudDisplayNotchContent(level: level), duration: 2))
            
        case .keyboard(let level):
            notchViewModel.send(.showTemporaryNotification(HudKeyboardNotchContent(level: level), duration: 2))
            
        case .volume(let level):
            notchViewModel.send(.showTemporaryNotification(HudVolumeNotchContent(level: level), duration: 2))
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
        guard !isOnboardingActive && !isAirDropActive else { return }
        
        switch event {
        case .connected:
            notchViewModel.send(.showTemporaryNotification(BluetoothConnectedNotchContent(bluetoothViewModel: bluetoothViewModel), duration: 5))
        }
    }
    
    func handleNetworkEvent(_ event: NetworkEvent) {
        guard !isOnboardingActive else { return }
        guard !isOnboardingActive && !isAirDropActive else { return }
        
        switch event {
        case .wifiConnected:
            notchViewModel.send(.showTemporaryNotification(WifiConnectedNotchContent(), duration: 3))
            
        case .vpnConnected:
            notchViewModel.send(.showTemporaryNotification(VpnConnectedNotchContent(), duration: 3))
            
        case .hotspotActive:
            notchViewModel.send(.showLiveActivity(HotspotActiveContent()))
            
        case .hotspotHide:
            notchViewModel.send(.hideLiveActivity(id: "hotspot.active"))
        }
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        guard !isOnboardingActive else { return }
        guard !isOnboardingActive && !isAirDropActive else { return }
        
        switch event {
        case .charger:
            notchViewModel.send(.showTemporaryNotification(ChargerNotchContent(powerService: powerService), duration: 4))
            
        case .lowPower:
            notchViewModel.send(.showTemporaryNotification(LowPowerNotchContent(powerService: powerService), duration: 4))
            
        case .fullPower:
            notchViewModel.send(.showTemporaryNotification(FullPowerNotchContent(powerService: powerService), duration: 4))
        }
    }
    
    func handleNowPlayingEvent(_ event: NowPlayingEvent) {
        guard !isOnboardingActive else { return }
        guard !isOnboardingActive && !isAirDropActive else { return }
        
        switch event {
        case .started:
            notchViewModel.send(.showLiveActivity(NowPlayingMinimalNotchContent(nowPlayingViewModel: nowPlayingViewModel)))
        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: "nowPlaying.minimal"))
        }
    }
}
