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
    private let hudViewModel: HudViewModel
    
    private var isOnboardingActive: Bool {
        notchViewModel.notchModel.liveActivityContent?.id == "onboarding" ||
        notchViewModel.notchModel.temporaryNotificationContent?.id == "onboarding"
    }
    
    init (
        notchViewModel: NotchViewModel,
        bluetoothViewModel: BluetoothViewModel,
        powerService: PowerService,
        networkViewModel: NetworkViewModel,
        hudViewModel: HudViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.bluetoothViewModel = bluetoothViewModel
        self.powerService = powerService
        self.networkViewModel = networkViewModel
        self.hudViewModel = hudViewModel
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
        notchViewModel.send(.hide)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        }
    }
    
    func handleHudEvent(_ event: HudEvent) {
        guard !isOnboardingActive else { return }
        
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
            notchViewModel.send(.showLiveActivitiy(OnboardingNotchContent(notchEventCoordinator: self)))
        }
    }
    
    func handleBluetoothEvent(_ event: BluetoothEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .connected:
            notchViewModel.send(.showTemporaryNotification(BluetoothConnectedNotchContent(bluetoothViewModel: bluetoothViewModel), duration: 5))
        }
    }
    
    func handleNetworkEvent(_ event: NetworkEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .wifiConnected:
            notchViewModel.send(.showTemporaryNotification(WifiConnectedNotchContent(), duration: 3))
            
        case .vpnConnected:
            notchViewModel.send(.showTemporaryNotification(VpnConnectedNotchContent(), duration: 3))
            
        case .hotspotActive:
            notchViewModel.send(.showLiveActivitiy(HotspotActiveContent()))
            
        case .hotspotHide:
            if notchViewModel.notchModel.liveActivityContent?.id == "hotspot.active" {
                notchViewModel.send(.hide)
            }
        }
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .charger:
            notchViewModel.send(.showTemporaryNotification(ChargerNotchContent(powerService: powerService), duration: 4))
            
        case .lowPower:
            notchViewModel.send(.showTemporaryNotification(LowPowerNotchContent(powerService: powerService), duration: 4))
            
        case .fullPower:
            notchViewModel.send(.showTemporaryNotification(FullPowerNotchContent(powerService: powerService), duration: 4))
        }
    }
}
