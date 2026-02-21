import SwiftUI
import Combine

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var state = NotchState()
    @Published var showNotch = false
    
    private var temporaryTask: Task<Void, Never>?
    private var suspendedActivity: NotchContent = .none
    private var isTransitioning = false
    private var hideDelay: TimeInterval = 0.3
    private var isOnboardingActive: Bool { state.activeContent == .onboarding || state.temporaryContent == .onboarding }
    
    init() {
        updateDimensions()
    }
    
    func updateDimensions() {
        guard let screen = NSScreen.main else { return }
        
        let screenWidth = screen.frame.width
        let topInset = screen.safeAreaInsets.top
        
        if topInset > 0 {
            state.baseHeight = topInset
            let ratio: CGFloat = screenWidth > 1700 ? 0.1325 : 0.1275
            state.baseWidth = floor(screenWidth * ratio)
            
        } else {
            state.baseHeight = 32
            state.baseWidth = 200
        }
    }
    
    func send(_ notchEvent: NotchEvent) {
        if isOnboardingActive {
            if case .hide = notchEvent { }
            else { return }
        }
        
        switch notchEvent {
        case .showLiveActivitiy(let content):
            showLiveActivitiy(content)
            
        case .showTemporaryNotification(let content, let duration):
            showTemporaryNotification(content, duration: duration)
            
        case .hide:
            hideTemporaryNotification()
        }
    }
    
    func handleStrokeVisibility(_ newValue: NotchContent) {
        if newValue != .none {
            updateDimensions()
            self.showNotch = true
            
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if self.state.activeContent == .none && self.state.temporaryContent == nil {
                    self.showNotch = false
                }
            }
        }
    }
    
    func toggleMusicExpanded() {
        guard case .music(let expandedState) = state.activeContent else { return }

        if expandedState == .none {
            transition(
                customDelay: 0,
                hide: {
                    withAnimation(.spring(response: 0.4)) {
                        self.state.activeContent = .none
                    }
                },
                show: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.state.activeContent = .music(.expanded)
                    }
                }
            )
        } else {
            transition(
                customDelay: 0.3,
                hide: {
                    withAnimation(.spring(response: 0.4)) {
                        self.state.activeContent = .none
                    }
                },
                show: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.state.activeContent = .music(.none)
                    }
                }
            )
        }
    }
    
    func handleOnboardingEvent(_ event: OnboardingEvent) {
        switch event {
        case .onboarding:
            send(.showLiveActivitiy(.onboarding))
        }
    }
    
    func handleBluetoothEvent(_ event: BluetoothEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .connected:
            send(.showTemporaryNotification(.bluetooth, duration: 5))
        }
    }
    
    func handleVpnEvent(_ event: VpnEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .connected:
            send(.showTemporaryNotification(.vpn(.connected), duration: 5))
        case .disconnected:
            send(.showTemporaryNotification(.vpn(.disconnected), duration: 5))
        }
    }
    
    func handleHudEvent(_ event: HudEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .display:
            send(.showTemporaryNotification(.systemHud(.display), duration: 2))
        case .keyboard:
            send(.showTemporaryNotification(.systemHud(.keyboard), duration: 2))
        case .volume:
            send(.showTemporaryNotification(.systemHud(.volume), duration: 2))
        }
    }
    
    func handlePowerEvent(_ event: PowerEvent) {
        guard !isOnboardingActive else { return }
        
        switch event {
        case .charger:
            send(.showTemporaryNotification(.battery(.charger), duration: 4))
            
        case .lowPower:
            send(.showTemporaryNotification(.battery(.lowPower), duration: 4))
            
        case .fullPower:
            send(.showTemporaryNotification(.battery(.fullPower), duration: 5))
        }
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
            self.state.activeContent = .none
            self.state.temporaryContent = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showNotch = false
        }
    }
    
    private func showLiveActivitiy(_ content: NotchContent) {
        if state.temporaryContent != nil {
            self.suspendedActivity = content
            return
        }
        
        transition(
            hide: {
                withAnimation(.spring(response: 0.4)) {
                    self.state.activeContent = .none
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.state.activeContent = content
                }
            }
        )
    }
    
    private func showTemporaryNotification(_ content: NotchContent, duration: TimeInterval) {
        transition(
            hide: {
                self.cancelTemporary()
                withAnimation(.spring(response: 0.4)) {
                    if self.state.activeContent != .none {
                        self.suspendedActivity = self.state.activeContent
                        self.state.activeContent = .none
                    }
                    self.state.temporaryContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.state.temporaryContent = content
                }
                
                if duration.isInfinite { return }
                
                self.temporaryTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    await MainActor.run {
                        self.hideTemporaryNotification()
                    }
                }
            }
        )
    }

    private func hideTemporaryNotification() {
        cancelTemporary()
        
        transition(
            hide: {
                withAnimation(.spring(response: 0.4)) {
                    self.state.temporaryContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.state.activeContent = self.suspendedActivity
                    self.suspendedActivity = .none
                }
            }
        )
    }
    
    private func transition(customDelay: TimeInterval? = nil, hide: @escaping () -> Void, show: @escaping () -> Void) {
        guard !isTransitioning else { return }
        isTransitioning = true
        
        let currentDelay = customDelay ?? self.hideDelay
        
        DispatchQueue.main.async {
            hide()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                show()
                self.isTransitioning = false
            }
        }
    }
    
    private func cancelTemporary() {
        temporaryTask?.cancel()
        temporaryTask = nil
    }
}
