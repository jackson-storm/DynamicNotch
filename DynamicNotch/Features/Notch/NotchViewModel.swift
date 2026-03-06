import SwiftUI
import Combine
import AppKit

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var notchModel = NotchModel()
    @Published private var activeLiveActivities: [NotchContentProtocol] = []
    @Published var showNotch = false
    @Published var showStroke = false
    @Published var isPressed = false
    @Published var cachedStrokeColor: Color = .clear
    
    private var highestPriorityActivity: NotchContentProtocol? { activeLiveActivities.sorted { $0.priority > $1.priority }.first }
    private var temporaryTask: Task<Void, Never>?
    private var suspendedActivity: NotchContentProtocol? = nil
    private var hideDelay: TimeInterval = 0.3
    private var queueDelay: TimeInterval = 0.3
    private var eventQueue: [NotchState] = []
    private var isProcessingQueue = false
    private var isTransitioning = false
    
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
            notchModel.baseWidth = 190 * notchModel.scale
        } else {
            notchModel.baseHeight = 25 * notchModel.scale
            notchModel.baseWidth = 190 * notchModel.scale
        }
    }
    
    // MARK: - Public Interface
    func send(_ notchState: NotchState) {
        switch notchState {
        case .showTemporaryNotification(let content, let duration):
            // Если это же уведомление уже на экране — обновляем его и сбрасываем таймер
            if notchModel.temporaryNotificationContent?.id == content.id {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notchModel.temporaryNotificationContent = content
                }
                restartTemporaryTimer(duration: duration)
                return
            }
            
        case .showLiveActivitiy(let content):
            updateLiveActivityStack(with: content)
            
            // Если эта активность уже на экране — просто обновляем её данные без анимации перехода
            if notchModel.liveActivityContent?.id == content.id {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notchModel.liveActivityContent = content
                }
                return
            }

        case .hideLiveActivity(let id):
            let wasVisible = notchModel.liveActivityContent?.id == id
            activeLiveActivities.removeAll(where: { $0.id == id })
            
            // Если удаляем то, что не было на экране — в очередь добавлять не нужно
            if !wasVisible {
                eventQueue.removeAll(where: {
                    if case .showLiveActivitiy(let content) = $0 { return content.id == id }
                    return false
                })
                return
            }

        case .hide:
            eventQueue.removeAll()
        }
        
        eventQueue.append(notchState)
        processQueue()
    }

    // MARK: - Queue Processing
    private func processQueue() {
        guard !isProcessingQueue, !eventQueue.isEmpty else { return }
        isProcessingQueue = true
        
        let state = eventQueue.removeFirst()
        
        Task {
            await executeState(state)
            
            if !eventQueue.isEmpty {
                try? await Task.sleep(nanoseconds: UInt64(queueDelay * 1_000_000_000))
            }
            
            isProcessingQueue = false
            processQueue()
        }
    }
    
    private func executeState(_ state: NotchState) async {
        while isTransitioning {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        switch state {
        case .showLiveActivitiy(let content):

            let current = notchModel.liveActivityContent
            let best = highestPriorityActivity

            // если это самая приоритетная активность
            if best?.id == content.id {
                await showLiveContentTransition(content)
            }
            // если текущая активность выше — ничего не делаем
            else if let current, current.priority >= content.priority {
                return
            }
            // если новая выше текущей
            else {
                await showLiveContentTransition(content)
            }

        case .hideLiveActivity(let id):

            let currentID = notchModel.liveActivityContent?.id

            if currentID == id {
                if let nextBest = highestPriorityActivity {
                    await showLiveContentTransition(nextBest)
                } else {
                    await hideAllTransition()
                }
            }

        case .showTemporaryNotification(let content, let duration):
            await showTemporaryTransition(content, duration: duration)

        case .hide:
            await hideAllTransition()
        }
    }

    // MARK: - Transitions
    private func showLiveContentTransition(_ content: NotchContentProtocol?) async {
        if notchModel.temporaryNotificationContent != nil {
            self.suspendedActivity = content
            return
        }
        
        if notchModel.liveActivityContent?.id == content?.id {
            return
        }
        
        return await withCheckedContinuation { continuation in
            transition(
                hide: { withAnimation(.spring(response: 0.5)) { self.notchModel.liveActivityContent = nil } },
                show: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self.notchModel.liveActivityContent = content
                    }
                    continuation.resume()
                }
            )
        }
    }

    private func showTemporaryTransition(_ content: NotchContentProtocol, duration: TimeInterval) async {
        return await withCheckedContinuation { continuation in
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
                    
                    if !duration.isInfinite {
                        self.temporaryTask = Task {
                            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                            self.hideTemporaryNotification()
                        }
                    }
                    continuation.resume()
                }
            )
        }
    }

    private func hideAllTransition() async {
        return await withCheckedContinuation { continuation in
            transition(
                hide: {
                    withAnimation(.spring(response: 0.5)) {
                        self.notchModel.temporaryNotificationContent = nil
                        self.notchModel.liveActivityContent = nil
                        self.suspendedActivity = nil
                    }
                },
                show: { continuation.resume() }
            )
        }
    }

    // MARK: - Helpers
    private func updateLiveActivityStack(with content: NotchContentProtocol) {
        if let index = activeLiveActivities.firstIndex(where: { $0.id == content.id }) {
            activeLiveActivities[index] = content
        } else {
            activeLiveActivities.append(content)
        }

        activeLiveActivities.sort { $0.priority > $1.priority }
    }

    func hideTemporaryNotification() {
        cancelTemporary()
        
        // После временного уведомления мы не просто возвращаем suspended,
        // а проверяем актуальный стек (на случай если активность удалили пока висел баннер)
        let contentToRestore = highestPriorityActivity
        
        transition(
            hide: { withAnimation(.spring(response: 0.5)) { self.notchModel.temporaryNotificationContent = nil } },
            show: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notchModel.liveActivityContent = contentToRestore
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

    private func restartTemporaryTimer(duration: TimeInterval) {
        cancelTemporary()
        if duration.isInfinite { return }
        temporaryTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            self.hideTemporaryNotification()
        }
    }
    
    func handleStrokeVisibility() {
        if let content = notchModel.content {
            cachedStrokeColor = content.strokeColor
            showStroke = true
            showNotch = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self, self.notchModel.content == nil else { return }
                self.showStroke = false
                self.showNotch = false
            }
        }
    }
}
