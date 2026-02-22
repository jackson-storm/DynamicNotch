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
                if self.state.liveActivityContent == .none && self.state.temporaryNotificationContent == nil {
                    self.showNotch = false
                }
            }
        }
    }
    
    func toggleMusicExpanded() {
        guard case .music(let expandedState) = state.liveActivityContent else { return }
        
        if expandedState == .none {
            transition(
                customDelay: 0,
                hide: {
                    withAnimation(.spring(response: 0.4)) {
                        self.state.liveActivityContent = .none
                    }
                },
                show: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.state.liveActivityContent = .music(.expanded)
                    }
                }
            )
        } else {
            transition(
                customDelay: 0.3,
                hide: {
                    withAnimation(.spring(response: 0.4)) {
                        self.state.liveActivityContent = .none
                    }
                },
                show: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        self.state.liveActivityContent = .music(.none)
                    }
                }
            )
        }
    }
    
    private func showLiveActivitiy(_ content: NotchContent) {
        if state.temporaryNotificationContent != nil {
            self.suspendedActivity = content
            return
        }
        
        transition(
            hide: {
                withAnimation(.spring(response: 0.5)) {
                    self.state.liveActivityContent = .none
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.state.liveActivityContent = content
                }
            }
        )
    }
    
    private func showTemporaryNotification(_ content: NotchContent, duration: TimeInterval) {
        transition(
            hide: {
                self.cancelTemporary()
                withAnimation(.spring(response: 0.5)) {
                    if self.state.liveActivityContent != .none {
                        self.suspendedActivity = self.state.liveActivityContent
                        self.state.liveActivityContent = .none
                    }
                    self.state.temporaryNotificationContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.state.temporaryNotificationContent = content
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
                withAnimation(.spring(response: 0.5)) {
                    self.state.temporaryNotificationContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.state.liveActivityContent = self.suspendedActivity
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
