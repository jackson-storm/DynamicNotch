import SwiftUI
import Combine

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var state = NotchModel()
    @Published var showNotch = false
    
    private var temporaryTask: Task<Void, Never>?
    private var suspendedActivity: NotchContentProvider? = nil
    private var isTransitioning = false
    private var hideDelay: TimeInterval = 0.3
    
    init() {
        updateDimensions()
    }
    
    func updateDimensions() {
        guard let screen = NSScreen.main else { return }
        
        let screenWidth = screen.frame.width
        let topInset = screen.safeAreaInsets.top
        let baseScreenWidth: CGFloat = 1440.0
        
        state.scale = max(0.35, screenWidth / baseScreenWidth)
        
        if topInset > 0 {
            state.baseHeight = topInset
            state.baseWidth = 188 * state.scale
        } else {
            state.baseHeight = 32 * state.scale
            state.baseWidth = 200 * state.scale
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
    
    func handleStrokeVisibility() {
        if state.content != nil {
            self.showNotch = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if self.state.liveActivityContent == nil && self.state.temporaryNotificationContent == nil {
                    self.showNotch = false
                }
            }
        }
    }
    
    func toggleMusicExpanded() {
        guard let currentId = state.liveActivityContent?.id, currentId.contains("music") else { return }
        
        let isExpanded = currentId.contains("expanded")
        let nextDelay: TimeInterval = isExpanded ? 0.3 : 0.2
        
        transition(
            customDelay: nextDelay,
            hide: {
                withAnimation(.spring(response: 0.5)) {
                    self.state.liveActivityContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    // Здесь логика переключения: если был compact, создаем expanded версию
                    // Вам нужно будет реализовать создание нового объекта контента
                    // self.state.liveActivityContent = isExpanded ? MusicCompact() : MusicExpanded()
                }
            }
        )
    }
    
    private func showLiveActivitiy(_ content: NotchContentProvider?) {
        if state.temporaryNotificationContent != nil {
            self.suspendedActivity = content
            return
        }
        
        transition(
            hide: {
                withAnimation(.spring(response: 0.5)) {
                    self.state.liveActivityContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.state.liveActivityContent = content
                }
            }
        )
    }
    
    private func showTemporaryNotification(_ content: NotchContentProvider, duration: TimeInterval) {
        transition(
            hide: {
                self.cancelTemporary()
                withAnimation(.spring(response: 0.5)) {
                    if self.state.liveActivityContent != nil {
                        self.suspendedActivity = self.state.liveActivityContent
                        self.state.liveActivityContent = nil
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
                    self.suspendedActivity = nil
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
