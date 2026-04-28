import SwiftUI
import Combine

private enum RestorableDismissedContent {
    case live(NotchContentProtocol)
    case temporary(NotchContentProtocol, duration: TimeInterval)
}

@MainActor
final class NotchEngine: ObservableObject {
    @Published private(set) var notchModel = NotchModel()
    @Published private(set) var showNotch = false
    @Published private(set) var cachedStrokeColor: Color = .clear

    private let animationsProvider: () -> NotchAnimations
    private let configuredHideDelay: TimeInterval?
    private let configuredQueueDelay: TimeInterval?

    private var activeLiveActivities: [NotchContentProtocol] = []
    private var dismissedLiveActivityIDs: [String] = []
    private var temporaryTask: Task<Void, Never>?
    private var temporaryTimerID = UUID()
    private var suspendedActivity: NotchContentProtocol?
    private var lastDismissedContent: RestorableDismissedContent?
    private var currentTemporaryNotificationDuration: TimeInterval?
    private var eventQueue: [NotchState] = []
    private var isProcessingQueue = false
    private var isTransitioning = false

    init(
        animations: @escaping () -> NotchAnimations,
        hideDelay: TimeInterval? = nil,
        queueDelay: TimeInterval? = nil
    ) {
        self.animationsProvider = animations
        self.configuredHideDelay = hideDelay
        self.configuredQueueDelay = queueDelay
    }

    var animations: NotchAnimations {
        animationsProvider()
    }

    private var hideDelay: TimeInterval {
        max(0, configuredHideDelay ?? animations.hideShowDelay)
    }

    private var queueDelay: TimeInterval {
        max(0, configuredQueueDelay ?? animations.queuePacingDelay)
    }

    var canExpandActiveLiveActivity: Bool {
        guard notchModel.temporaryNotificationContent == nil else { return false }
        guard let liveActivityContent = notchModel.liveActivityContent else { return false }

        return !notchModel.isLiveActivityExpanded &&
        liveActivityContent.isExpandable &&
        liveActivityContent.expandsOnTap
    }

    var canRestoreDismissedContent: Bool {
        lastDismissedContent != nil || !dismissedLiveActivityIDs.isEmpty
    }

    var canOpenActiveWindowLink: Bool {
        notchModel.content?.windowLink != nil
    }

    func updateBaseGeometry(width: CGFloat, height: CGFloat, scale: CGFloat) {
        notchModel.baseWidth = width
        notchModel.baseHeight = height
        notchModel.scale = scale
    }

    func send(_ notchState: NotchState) {
        switch notchState {
        case .showTemporaryNotification(let content, let duration):
            if notchModel.temporaryNotificationContent?.id == content.id {
                currentTemporaryNotificationDuration = duration

                withAnimation(animations.contentUpdate) {
                    notchModel.temporaryNotificationContent = content
                }

                restartTemporaryTimer(duration: duration)
                eventQueue.removeAll {
                    if case .showTemporaryNotification(let queuedContent, _) = $0 {
                        return queuedContent.id == content.id
                    }
                    return false
                }
                return
            }

        case .showLiveActivity(let content):
            updateLiveActivityStack(with: content)

            if notchModel.liveActivityContent?.id == content.id {
                withAnimation(animations.contentUpdate) {
                    notchModel.liveActivityContent = content
                }
                return
            }

        case .hideLiveActivity(let id):
            let wasVisible = notchModel.liveActivityContent?.id == id
            activeLiveActivities.removeAll(where: { $0.id == id })
            dismissedLiveActivityIDs.removeAll(where: { $0 == id })
            if case .live(let dismissedContent) = lastDismissedContent,
               dismissedContent.id == id {
                lastDismissedContent = nil
            }

            if !wasVisible {
                eventQueue.removeAll {
                    if case .showLiveActivity(let content) = $0 {
                        return content.id == id
                    }
                    return false
                }
                return
            }

        case .hide:
            eventQueue.removeAll()

        case .dismissLiveActivity:
            break
        }

        eventQueue.append(notchState)
        processQueue()
    }

    func hideTemporaryNotification() {
        guard notchModel.temporaryNotificationContent != nil else { return }

        cancelTemporary()
        let contentToRestore = highestPriorityVisibleActivity

        transition(
            hide: {
                withAnimation(self.animations.contentHide) {
                    self.notchModel.temporaryNotificationContent = nil
                    self.currentTemporaryNotificationDuration = nil
                }
            },
            show: {
                withAnimation(self.animations.contentShow) {
                    self.notchModel.liveActivityContent = contentToRestore
                    self.suspendedActivity = nil
                }
            }
        )
    }

    func dismissActiveContent() {
        if let temporaryContent = notchModel.temporaryNotificationContent {
            lastDismissedContent = .temporary(
                temporaryContent,
                duration: currentTemporaryNotificationDuration ?? .infinity
            )
            hideTemporaryNotification()
            return
        }

        guard let liveActivityContent = notchModel.liveActivityContent else { return }
        lastDismissedContent = .live(liveActivityContent)
        recordDismissedLiveActivity(id: liveActivityContent.id)
        send(.dismissLiveActivity(id: liveActivityContent.id))
    }

    func restoreDismissedContent() {
        if let lastDismissedContent {
            self.lastDismissedContent = nil

            switch lastDismissedContent {
            case .live(let content):
                restoreDismissedLiveActivity(preferredID: content.id)

            case .temporary(let content, let duration):
                send(.showTemporaryNotification(content, duration: duration))
            }
            return
        }

        restoreDismissedLiveActivity()
    }

    func refreshLiveActivityPriorities() {
        sortActiveLiveActivitiesByPriority()

        guard let bestVisible = highestPriorityVisibleActivity else {
            return
        }

        if notchModel.temporaryNotificationContent != nil {
            suspendedActivity = bestVisible
            return
        }

        guard bestVisible.id != notchModel.liveActivityContent?.id else {
            return
        }

        eventQueue.append(.showLiveActivity(bestVisible))
        processQueue()
    }

    func openActiveWindowLink() {
        notchModel.content?.windowLink?()
    }

    func handleActiveContentTap() {
        guard canExpandActiveLiveActivity else { return }

        withAnimation(animations.expandLiveActivity) {
            notchModel.isLiveActivityExpanded = true
        }
    }

    func handleOutsideClick() {
        guard notchModel.isLiveActivityExpanded,
              let liveActivityContent = notchModel.liveActivityContent else { return }

        transition(
            hide: {
                withAnimation(self.animations.contentHide) {
                    self.notchModel.isLiveActivityExpanded = false
                    self.notchModel.liveActivityContent = nil
                }
            },
            show: {
                withAnimation(self.animations.contentShow) {
                    self.notchModel.liveActivityContent = liveActivityContent
                }
            }
        )
    }

    func handleStrokeVisibility() {
        if let content = notchModel.content {
            cachedStrokeColor = content.strokeColor
            showNotch = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self, self.notchModel.content == nil else { return }
                self.cachedStrokeColor = .clear
                self.showNotch = false
            }
        }
    }

    private var highestPriorityVisibleActivity: NotchContentProtocol? {
        activeLiveActivities.first { dismissedLiveActivityIDs.contains($0.id) == false }
    }

    private func recordDismissedLiveActivity(id: String) {
        dismissedLiveActivityIDs.removeAll(where: { $0 == id })
        dismissedLiveActivityIDs.append(id)
    }

    private func restoreDismissedLiveActivity(preferredID: String? = nil) {
        if let preferredID {
            dismissedLiveActivityIDs.removeAll(where: { $0 == preferredID })

            if let content = activeLiveActivities.first(where: { $0.id == preferredID }) {
                send(.showLiveActivity(content))
                return
            }
        }

        while let nextID = dismissedLiveActivityIDs.popLast() {
            if let content = activeLiveActivities.first(where: { $0.id == nextID }) {
                send(.showLiveActivity(content))
                return
            }
        }
    }

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
        case .showLiveActivity(let content):
            if dismissedLiveActivityIDs.contains(content.id) {
                return
            }

            let bestVisible = highestPriorityVisibleActivity

            if bestVisible?.id == notchModel.liveActivityContent?.id {
                return
            }

            await showLiveContentTransition(bestVisible)

        case .hideLiveActivity(let id):
            if notchModel.liveActivityContent?.id == id {
                if let nextBest = highestPriorityVisibleActivity {
                    await showLiveContentTransition(nextBest)
                } else {
                    await showLiveContentTransition(nil)
                }
            }

        case .dismissLiveActivity(let id):
            guard notchModel.liveActivityContent?.id == id else { return }
            await showLiveContentTransition(highestPriorityVisibleActivity)

        case .showTemporaryNotification(let content, let duration):
            await showTemporaryTransition(content, duration: duration)

        case .hide:
            await hideAllTransition()
        }
    }

    private func showLiveContentTransition(_ content: NotchContentProtocol?) async {
        if notchModel.temporaryNotificationContent != nil {
            suspendedActivity = content
            return
        }

        if notchModel.liveActivityContent?.id == content?.id {
            return
        }

        await withCheckedContinuation { continuation in
            transition(
                hide: {
                    withAnimation(self.animations.contentHide) {
                        self.notchModel.isLiveActivityExpanded = false
                        self.notchModel.liveActivityContent = nil
                    }
                },
                show: {
                    withAnimation(self.animations.contentShow) {
                        self.notchModel.liveActivityContent = content
                    }
                    continuation.resume()
                }
            )
        }
    }

    private func showTemporaryTransition(_ content: NotchContentProtocol, duration: TimeInterval) async {
        await withCheckedContinuation { continuation in
            transition(
                hide: {
                    self.cancelTemporary()

                    withAnimation(self.animations.contentHide) {
                        if self.notchModel.liveActivityContent != nil {
                            self.suspendedActivity = self.notchModel.liveActivityContent
                            self.notchModel.isLiveActivityExpanded = false
                            self.notchModel.liveActivityContent = nil
                        }

                        self.notchModel.temporaryNotificationContent = nil
                    }
                },
                show: {
                    withAnimation(self.animations.contentShow) {
                        self.notchModel.temporaryNotificationContent = content
                    }
                    self.currentTemporaryNotificationDuration = duration

                    if !duration.isInfinite {
                        self.restartTemporaryTimer(duration: duration)
                    }

                    continuation.resume()
                }
            )
        }
    }

    private func hideAllTransition() async {
        await withCheckedContinuation { continuation in
            transition(
                hide: {
                    withAnimation(self.animations.contentHide) {
                        self.notchModel.isLiveActivityExpanded = false
                        self.notchModel.temporaryNotificationContent = nil
                        self.notchModel.liveActivityContent = nil
                        self.suspendedActivity = nil
                        self.currentTemporaryNotificationDuration = nil
                    }
                },
                show: {
                    continuation.resume()
                }
            )
        }
    }

    private func updateLiveActivityStack(with content: NotchContentProtocol) {
        if let index = activeLiveActivities.firstIndex(where: { $0.stackID == content.stackID }) {
            activeLiveActivities[index] = content
        } else {
            activeLiveActivities.append(content)
        }

        sortActiveLiveActivitiesByPriority()
    }

    private func sortActiveLiveActivitiesByPriority() {
        activeLiveActivities.sort { lhs, rhs in
            if lhs.priority == rhs.priority {
                return lhs.id < rhs.id
            }

            return lhs.priority > rhs.priority
        }
    }

    private func transition(customDelay: TimeInterval? = nil, hide: @escaping () -> Void, show: @escaping () -> Void) {
        guard !isTransitioning else { return }

        isTransitioning = true
        let currentDelay = customDelay ?? hideDelay

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

        let timerID = UUID()
        temporaryTimerID = timerID

        temporaryTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

            await MainActor.run {
                guard self.temporaryTimerID == timerID else { return }
                self.hideTemporaryNotification()
            }
        }
    }
}
