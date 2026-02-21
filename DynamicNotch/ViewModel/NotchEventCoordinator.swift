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
    
    private var isOnboardingActive: Bool {
        notchViewModel.state.liveActivityContent == .onboarding ||
        notchViewModel.state.temporaryNotificationContent == .onboarding
    }
    
    init(notchViewModel: NotchViewModel) {
        self.notchViewModel = notchViewModel
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
        
        withAnimation(.spring(response: 0.5)) {
            notchViewModel.send(.hide)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.notchViewModel.send(.showLiveActivitiy(.none))
        }
    }
    
    func handleOnboardingEvent(_ event: OnboardingEvent) {
        switch event {
        case .onboarding:
            notchViewModel.send(.showLiveActivitiy(.onboarding))
        }
    }
    
    func handleBluetoothEvent(_ event: BluetoothEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .connected:
            notchViewModel.send(.showTemporaryNotification(.bluetooth, duration: 5))
        }
    }
    
    func handleVpnEvent(_ event: VpnEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .connected:
            notchViewModel.send(.showTemporaryNotification(.vpn(.connected), duration: 5))
        case .disconnected:
            notchViewModel.send(.showTemporaryNotification(.vpn(.disconnected), duration: 5))
        }
    }
    
    func handleHudEvent(_ event: HudEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .display:
            notchViewModel.send(.showTemporaryNotification(.systemHud(.display), duration: 2))
        case .keyboard:
            notchViewModel.send(.showTemporaryNotification(.systemHud(.keyboard), duration: 2))
        case .volume:
            notchViewModel.send(.showTemporaryNotification(.systemHud(.volume), duration: 2))
        }
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .charger:
            notchViewModel.send(.showTemporaryNotification(.battery(.charger), duration: 4))
        case .lowPower:
            notchViewModel.send(.showTemporaryNotification(.battery(.lowPower), duration: 4))
        case .fullPower:
            notchViewModel.send(.showTemporaryNotification(.battery(.fullPower), duration: 5))
        }
    }
}
