import SwiftUI
import Combine

private enum RestorableDismissedContent {
    case live(NotchContentProtocol)
    case temporary(NotchContentProtocol, duration: TimeInterval)
}

/// Central presentation engine coordinating Live Activities and Dynamic Island presentations.
///
/// **Apple LiveActivity & Dynamic Island Lifecycle Management:**
/// - Maintains the active presentation state model (`NotchModel`).
/// - Coordinates priority-based scheduling for concurrent Live Activities (`NotchContentProtocol`).
/// - Handles transient alert / HUD preemption and restoration of background Live Activities.
/// - Manages interactive transitions between Compact and Expanded presentation modes.
@MainActor
final class NotchEngine: ObservableObject {
    /// Active visual state model representing the Notch / Dynamic Island presentation.
    @Published private(set) var notchModel = NotchModel()

    /// Visibility flag controlling whether the notch surface is visible.
    @Published private(set) var showNotch = false

    /// Cached border stroke color for smooth fade-out animations when content hides.
    @Published private(set) var cachedStrokeColor: Color = .clear

    private let animationsProvider: () -> NotchAnimations
    private let configuredHideDelay: TimeInterval?
    private let configuredQueueDelay: TimeInterval?

    /// Priority-ordered stack of currently active Live Activities (Apple: active `Activity<Attributes>` instances).
    private var activeLiveActivities: [NotchContentProtocol] = []

    /// Unique IDs of Live Activities dismissed by the user (swiped away / dismissed from the Dynamic Island).
    private var dismissedLiveActivityIDs: [String] = []

    private var temporaryTask: Task<Void, Never>?
    private var temporaryTimerID = UUID()

    /// Live Activity temporarily preempted/suspended while a transient alert is active.
    private var suspendedActivity: NotchContentProtocol?

    /// Last dismissed activity or alert saved for user restoration.
    private var lastDismissedContent: RestorableDismissedContent?

    private(set) var preferredLiveActivityID: String?

    func setPreferredLiveActivity(id: String?) {
        preferredLiveActivityID = id
    }

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
        max(0, configuredHideDelay ?? animations.transitionDelay)
    }

    private var queueDelay: TimeInterval {
        max(0, configuredQueueDelay ?? animations.queuePacingDelay)
    }

    private var strokeHideDelay: TimeInterval {
        max(0, hideDelay + 0.01)
    }

    /// Checks whether the active Live Activity can expand from compact into expanded presentation mode.
    var canExpandActiveLiveActivity: Bool {
        guard let content = notchModel.content else { return false }

        return !notchModel.isExpanded &&
        content.isExpandable &&
        content.expandsOnTap
    }

    /// Apple LiveActivity equivalent: Whether current presentation can expand.
    var canExpand: Bool {
        canExpandActiveLiveActivity
    }

    /// Checks whether there is a previously dismissed Live Activity or notification that can be restored.
    var canRestoreDismissedContent: Bool {
        lastDismissedContent != nil || !dismissedLiveActivityIDs.isEmpty
    }

    /// Apple LiveActivity equivalent: Whether dismissed content can be restored.
    var canRestore: Bool {
        canRestoreDismissedContent
    }

    /// Checks whether the currently presented content provides a deep link / app window action.
    var canOpenActiveWindowLink: Bool {
        notchModel.content?.windowLink != nil || notchModel.content?.widgetURL != nil
    }

    /// Apple LiveActivity equivalent: Whether active content provides a widgetURL / deep-link.
    var canOpenWidgetURL: Bool {
        canOpenActiveWindowLink
    }

    /// Updates the hardware geometry metrics (Notch bezel vs Dynamic Island floating pill).
    func updateBaseGeometry(width: CGFloat, height: CGFloat, scale: CGFloat, isDynamicIsland: Bool) {
        guard notchModel.baseWidth != width ||
              notchModel.baseHeight != height ||
              notchModel.scale != scale ||
              notchModel.isDynamicIsland != isDynamicIsland else {
            return
        }
        notchModel.baseWidth = width
        notchModel.baseHeight = height
        notchModel.scale = scale
        notchModel.isDynamicIsland = isDynamicIsland
        notchModel.updateToken = UUID()
    }

    /// Dispatches a state transition event driving the Live Activity / Alert lifecycle.
    ///
    /// Corresponds to Apple's `ActivityKit` lifecycle management (`Activity.request`, `update`, `end`, and Dynamic Island dismissal).
    func send(_ notchState: NotchState) {
        switch notchState {
        case .showTemporaryNotification(let content, let duration):
            if notchModel.temporaryNotificationContent?.id == content.id {
                currentTemporaryNotificationDuration = duration

                withAnimation(animations.updateContent) {
                    notchModel.temporaryNotificationContent = content
                    notchModel.updateToken = UUID()
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

            if let index = eventQueue.firstIndex(where: {
                if case .showTemporaryNotification(let queuedContent, _) = $0 {
                    return queuedContent.id == content.id
                }
                return false
            }) {
                eventQueue[index] = notchState
                return
            }

        case .showLiveActivity(let content):
            dismissedLiveActivityIDs.removeAll(where: { $0 == content.id })
            updateLiveActivityStack(with: content)

            if notchModel.liveActivityContent?.id == content.id {
                withAnimation(animations.updateContent) {
                    notchModel.liveActivityContent = content
                    notchModel.updateToken = UUID()
                }
                return
            }

        case .hideLiveActivity(let id):
            if preferredLiveActivityID == id {
                preferredLiveActivityID = nil
            }
            let wasVisible = notchModel.liveActivityContent?.id == id
            activeLiveActivities.removeAll(where: { $0.id == id })
            dismissedLiveActivityIDs.removeAll(where: { $0 == id })
            if suspendedActivity?.id == id {
                suspendedActivity = nil
            }
            if case .live(let dismissedContent) = lastDismissedContent,
               dismissedContent.id == id {
                lastDismissedContent = nil
            }

            eventQueue.removeAll {
                if case .showLiveActivity(let content) = $0 {
                    return content.id == id
                }
                return false
            }

            if !wasVisible {
                return
            }

        case .hide:
            preferredLiveActivityID = nil
            eventQueue.removeAll()

        case .dismissLiveActivity:
            break
        }

        eventQueue.append(notchState)
        processQueue()
    }

    /// Hides the active transient alert/notification and restores the highest-priority suspended Live Activity.
    func hideTemporaryNotification() {
        guard notchModel.temporaryNotificationContent != nil,
              !notchModel.isLiveActivityExpanded else { return }

        cancelTemporary()
        let contentToRestore = highestPriorityVisibleActivity

        transition(
            hide: {
                withAnimation(self.animations.hideContent) {
                    self.notchModel.temporaryNotificationContent = nil
                    self.currentTemporaryNotificationDuration = nil
                }
            },
            show: {
                withAnimation(self.animations.showContent) {
                    self.notchModel.liveActivityContent = contentToRestore
                    self.suspendedActivity = nil
                }
            }
        )
    }

    /// Dismisses the currently presented activity or notification (swiped away / user dismissed).
    /// If restorable, saves the content to the dismissed stack for subsequent restoration.
    func dismissActiveContent() {
        if let temporaryContent = notchModel.temporaryNotificationContent {
            if temporaryContent.isRestorable {
                lastDismissedContent = .temporary(
                    temporaryContent,
                    duration: currentTemporaryNotificationDuration ?? .infinity
                )
            }
            hideTemporaryNotification()
            return
        }

        guard let liveActivityContent = notchModel.liveActivityContent else { return }
        if liveActivityContent.isRestorable {
            lastDismissedContent = .live(liveActivityContent)
            recordDismissedLiveActivity(id: liveActivityContent.id)
            send(.dismissLiveActivity(id: liveActivityContent.id))
        } else {
            send(.hideLiveActivity(id: liveActivityContent.id))
        }
    }

    /// Restores the most recently dismissed Live Activity or notification to the Dynamic Island presentation.
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

    /// Re-evaluates priorities among registered active Live Activities and presents the highest-priority one.
    /// Maps to Apple's multi-activity scheduling in the Dynamic Island.
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

    /// Triggers the deep-link / window action of the active content to open the host application.
    func openActiveWindowLink() {
        if let widgetURL = notchModel.content?.widgetURL {
            widgetURL()
        } else {
            notchModel.content?.windowLink?()
        }
    }

    /// Handles user tap to expand the Dynamic Island from Compact mode to Expanded presentation mode.
    func handleActiveContentTap() {
        guard canExpandActiveLiveActivity else { return }

        if notchModel.temporaryNotificationContent != nil {
            cancelTemporary()
        }

        withAnimation(animations.expandLiveActivity) {
            notchModel.isExpanded = true
        }
    }

    /// Handles user clicks outside the expanded island to collapse it back to Compact presentation mode.
    func handleOutsideClick() {
        if UserDefaults.standard.bool(forKey: "isNotchLocked") {
            return
        }

        guard notchModel.isLiveActivityExpanded else { return }

        if let temporaryContent = notchModel.temporaryNotificationContent {
            let duration = currentTemporaryNotificationDuration
            transition(
                hide: {
                    withAnimation(self.animations.collapseLiveActivity) {
                        self.notchModel.isLiveActivityExpanded = false
                        self.notchModel.temporaryNotificationContent = nil
                    }
                },
                show: {
                    withAnimation(self.animations.showContent) {
                        self.notchModel.temporaryNotificationContent = temporaryContent
                    }
                    if let duration, !duration.isInfinite {
                        self.restartTemporaryTimer(duration: duration)
                    }
                }
            )
            return
        }

        guard let liveActivityContent = notchModel.liveActivityContent else { return }

        transition(
            hide: {
                withAnimation(self.animations.collapseLiveActivity) {
                    self.notchModel.isLiveActivityExpanded = false
                    self.notchModel.liveActivityContent = nil
                }
            },
            show: {
                withAnimation(self.animations.showContent) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + strokeHideDelay) { [weak self] in
                guard let self, self.notchModel.content == nil else { return }
                self.cachedStrokeColor = .clear
                self.showNotch = false
            }
        }
    }

    private var highestPriorityVisibleActivity: NotchContentProtocol? {
        if let preferredLiveActivityID,
           let preferred = activeLiveActivities.first(where: { $0.id == preferredLiveActivityID && !dismissedLiveActivityIDs.contains($0.id) }) {
            return preferred
        }
        return activeLiveActivities.first { dismissedLiveActivityIDs.contains($0.id) == false }
    }

    private func recordDismissedLiveActivity(id: String) {
        if preferredLiveActivityID == id {
            preferredLiveActivityID = nil
        }
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
            dismissedLiveActivityIDs.removeAll(where: { $0 == content.id })

            let bestVisible = highestPriorityVisibleActivity

            if bestVisible?.id == notchModel.liveActivityContent?.id {
                if let bestVisible {
                    notchModel.liveActivityContent = bestVisible
                    notchModel.updateToken = UUID()
                }
                return
            }

            await showLiveContentTransition(bestVisible)

        case .hideLiveActivity(let id):
            if suspendedActivity?.id == id {
                suspendedActivity = nil
            }
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
            if notchModel.temporaryNotificationContent?.id == content.id {
                currentTemporaryNotificationDuration = duration
                withAnimation(animations.updateContent) {
                    notchModel.temporaryNotificationContent = content
                    notchModel.updateToken = UUID()
                }
                if !notchModel.isLiveActivityExpanded {
                    restartTemporaryTimer(duration: duration)
                }
            } else {
                await showTemporaryTransition(content, duration: duration)
            }

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

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let didStart = transition(
                customDelay: (notchModel.content == nil) ? 0.0 : nil,
                hide: {
                    withAnimation(self.animations.collapseLiveActivity) {
                        self.notchModel.isLiveActivityExpanded = false
                        self.notchModel.liveActivityContent = nil
                    }
                },
                show: {
                    withAnimation(self.animations.showContent) {
                        self.notchModel.liveActivityContent = content
                    }
                    continuation.resume()
                }
            )
            if !didStart {
                continuation.resume()
            }
        }
    }

    private func showTemporaryTransition(_ content: NotchContentProtocol, duration: TimeInterval) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let didStart = transition(
                customDelay: (notchModel.content == nil) ? 0.0 : nil,
                hide: {
                    self.cancelTemporary()

                    withAnimation(self.notchModel.isLiveActivityExpanded ? self.animations.collapseLiveActivity : self.animations.hideContent) {
                        if self.notchModel.liveActivityContent != nil {
                            self.suspendedActivity = self.notchModel.liveActivityContent
                            self.notchModel.isLiveActivityExpanded = false
                            self.notchModel.liveActivityContent = nil
                        }

                        self.notchModel.temporaryNotificationContent = nil
                    }
                },
                show: {
                    withAnimation(self.animations.showContent) {
                        self.notchModel.temporaryNotificationContent = content
                    }
                    self.currentTemporaryNotificationDuration = duration

                    if !duration.isInfinite {
                        self.restartTemporaryTimer(duration: duration)
                    }

                    continuation.resume()
                }
            )
            if !didStart {
                continuation.resume()
            }
        }
    }

    private func hideAllTransition() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let didStart = transition(
                hide: {
                    withAnimation(self.notchModel.isLiveActivityExpanded ? self.animations.collapseLiveActivity : self.animations.hideContent) {
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
            if !didStart {
                continuation.resume()
            }
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

    @discardableResult
    private func transition(customDelay: TimeInterval? = nil, hide: @escaping () -> Void, show: @escaping () -> Void) -> Bool {
        guard !isTransitioning else { return false }

        isTransitioning = true
        let currentDelay = customDelay ?? hideDelay

        DispatchQueue.main.async {
            hide()

            DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                show()
                self.isTransitioning = false
            }
        }
        return true
    }

    private func cancelTemporary() {
        temporaryTask?.cancel()
        temporaryTask = nil
    }

    private func restartTemporaryTimer(duration: TimeInterval) {
        cancelTemporary()

        guard !notchModel.isLiveActivityExpanded else { return }
        if duration.isInfinite { return }

        let timerID = UUID()
        temporaryTimerID = timerID

        temporaryTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard self.temporaryTimerID == timerID,
                      !self.notchModel.isLiveActivityExpanded else { return }
                self.hideTemporaryNotification()
            }
        }
    }
}
