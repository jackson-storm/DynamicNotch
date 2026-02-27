import SwiftUI
import Combine

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var notchModel = NotchModel()
    @Published var showNotch = false
    @Published var showStroke = false
    
    private var temporaryTask: Task<Void, Never>?
    private var suspendedActivity: NotchContentProtocol? = nil
    
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
        
        notchModel.scale = max(0.35, screenWidth / baseScreenWidth)
        
        if topInset > 0 {
            notchModel.baseHeight = topInset
            notchModel.baseWidth = 188 * notchModel.scale
        } else {
            notchModel.baseHeight = 32 * notchModel.scale
            notchModel.baseWidth = 200 * notchModel.scale
        }
    }
    
    func send(_ notchState: NotchState) {
        switch notchState {
        case .showLiveActivitiy(let content):
            showLiveActivitiy(content)
            
        case .showTemporaryNotification(let content, let duration):
            showTemporaryNotification(content, duration: duration)
            
        case .hide:
            hideTemporaryNotification()
        }
    }
    
    func handleStrokeVisibility() {
        if notchModel.content != nil {
            showStroke = true
            showNotch = true
            
        } else {
            let delay = hideDelay + 0.5
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                
                if self.notchModel.content == nil {
                    self.showStroke = false
                    self.showNotch = false
                }
            }
        }
    }
    
    func toggleMusicExpanded() {
        guard let currentId = notchModel.liveActivityContent?.id, currentId.contains("music") else { return }
        
        let isExpanded = currentId.contains("expanded")
        let nextDelay: TimeInterval = isExpanded ? 0.3 : 0.2
        
        transition(
            customDelay: nextDelay,
            hide: {
                withAnimation(.spring(response: 0.5)) {
                    self.notchModel.liveActivityContent = nil
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
    
    private func showLiveActivitiy(_ content: NotchContentProtocol?) {
        if notchModel.temporaryNotificationContent != nil {
            self.suspendedActivity = content
            return
        }
        
        transition(
            hide: {
                withAnimation(.spring(response: 0.5)) {
                    self.notchModel.liveActivityContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notchModel.liveActivityContent = content
                }
            }
        )
    }
    
    private func showTemporaryNotification(_ content: NotchContentProtocol, duration: TimeInterval) {
        transition(
            hide: {
                self.cancelTemporary()
                withAnimation(.spring(response: 0.5)) {
                    if self.notchModel.liveActivityContent != nil {
                        self.suspendedActivity = self.notchModel.liveActivityContent
                        self.notchModel.liveActivityContent = nil
                    }
                    self.notchModel.temporaryNotificationContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notchModel.temporaryNotificationContent = content
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
                    self.notchModel.temporaryNotificationContent = nil
                }
            },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notchModel.liveActivityContent = self.suspendedActivity
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
