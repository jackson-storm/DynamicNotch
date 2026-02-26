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
    private let powerSourceMonitor: PowerSourceMonitor
    
    private var isOnboardingActive: Bool {
        notchViewModel.notchModel.liveActivityContent?.id == "onboarding" ||
        notchViewModel.notchModel.temporaryNotificationContent?.id == "onboarding"
    }
    
    init(notchViewModel: NotchViewModel, bluetoothViewModel: BluetoothViewModel, powerSourceMonitor: PowerSourceMonitor) {
        self.notchViewModel = notchViewModel
        self.bluetoothViewModel = bluetoothViewModel
        self.powerSourceMonitor = powerSourceMonitor
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
            notchViewModel.send(
                .showTemporaryNotification(
                    BluetoothNotchContent(bluetoothViewModel: bluetoothViewModel),
                    duration: 5
                )
            )
        }
    }
    
    func handleVpnEvent(_ event: VpnEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .connected:
            notchViewModel.send(.showTemporaryNotification(VpnConnectedNotchContent(), duration: 5))
        case .disconnected:
            notchViewModel.send(.showTemporaryNotification(VpnDisconnectedNotchContent(), duration: 5))
        }
    }
    
    func handleWifiEvent(_ event: WiFiEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .connected:
            notchViewModel.send(.showTemporaryNotification(WifiConnectedNotchContent(), duration: 5))
        case .disconnected:
            notchViewModel.send(.showTemporaryNotification(WifiDisconnectedNotchContent(), duration: 5))
        }
    }
    
    func handleHudEvent(_ event: HudEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .display:
            notchViewModel.send(.showTemporaryNotification(HudDisplayNotchContent(), duration: 2))
        case .keyboard:
            notchViewModel.send(.showTemporaryNotification(HudKeyboardNotchContent(), duration: 2))
        case .volume:
            notchViewModel.send(.showTemporaryNotification(HudVolumeNotchContent(), duration: 2))
        }
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .charger:
            notchViewModel.send(.showTemporaryNotification(ChargerNotchContent(powerMonitor: powerSourceMonitor), duration: 5))
        case .lowPower:
            notchViewModel.send(.showTemporaryNotification(LowPowerNotchContent(powerMonitor: powerSourceMonitor), duration: 5))
        case .fullPower:
            notchViewModel.send(.showTemporaryNotification(FullPowerNotchContent(powerMonitor: powerSourceMonitor), duration: 5))
        }
    }
}
