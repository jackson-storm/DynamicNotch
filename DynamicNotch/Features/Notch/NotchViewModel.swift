import SwiftUI
import Combine
import AppKit

/// ViewModel controlling the Dynamic Notch state machine.
/// Handles event queueing, priority resolution, temporary notifications
/// and animated transitions between different notch contents.
///
/// Architecture:
/// External events → send() → eventQueue → executeState() → NotchModel → SwiftUI UI
@MainActor
final class NotchViewModel: ObservableObject {

    /// Single source of truth for the current notch UI state
    @Published private(set) var notchModel = NotchModel()

    /// Stack of active Live Activities (sorted by priority)
    @Published private var activeLiveActivities: [NotchContentProtocol] = []

    /// UI interaction state
    @Published var showNotch = false
    @Published var isPressed = false

    /// Cached stroke color used when notch content changes
    @Published var cachedStrokeColor: Color = .clear

    /// Settings dependency used to calculate notch dimensions
    private let settings: NotchSettingsProviding

    /// Returns the currently highest priority Live Activity
    private var highestPriorityActivity: NotchContentProtocol? {
        activeLiveActivities.sorted { $0.priority > $1.priority }.first
    }

    /// Async task controlling lifetime of temporary notifications
    private var temporaryTask: Task<Void, Never>?

    /// Unique token identifying the currently active temporary timer.
    /// Prevents outdated timers from closing newer notifications.
    private var temporaryTimerID = UUID()

    /// Suspended activity while temporary notification is visible
    private var suspendedActivity: NotchContentProtocol? = nil

    /// Animation delay used between hide/show phases
    private var hideDelay: TimeInterval = 0.3

    /// Delay between queue events
    private var queueDelay: TimeInterval = 0.3

    /// Event queue ensuring sequential processing of notch events
    private var eventQueue: [NotchState] = []

    /// Prevents parallel queue execution
    private var isProcessingQueue = false

    /// Prevents overlapping transitions
    private var isTransitioning = false


    init(
        settings: NotchSettingsProviding,
        hideDelay: TimeInterval = 0.3,
        queueDelay: TimeInterval = 0.3
    ) {
        self.settings = settings
        self.hideDelay = hideDelay
        self.queueDelay = queueDelay
        updateDimensions()
    }


    /// Updates notch dimensions based on screen size and user settings
    func updateDimensions() {
        guard let screen = NSScreen.main else { return }

        let screenWidth = screen.frame.width
        let topInset = screen.safeAreaInsets.top
        let baseScreenWidth: CGFloat = 1440.0

        notchModel.scale = max(0.35, screenWidth / baseScreenWidth)

        let widthOffset = CGFloat(settings.notchWidth)
        let heightOffset = CGFloat(settings.notchHeight)

        if topInset > 0 {
            notchModel.baseHeight = topInset + heightOffset
            notchModel.baseWidth = (190 * notchModel.scale) + widthOffset
        } else {
            notchModel.baseHeight = (25 * notchModel.scale) + heightOffset
            notchModel.baseWidth = (190 * notchModel.scale) + widthOffset
        }
    }


    /// Main entry point for all notch events.
    /// Events are normalized, deduplicated and then queued for processing.
    func send(_ notchState: NotchState) {

        switch notchState {

        case .showTemporaryNotification(let content, let duration):

            /// If the same temporary notification is already visible,
            /// update its content and restart the timer instead of creating
            /// a new transition.
            if notchModel.temporaryNotificationContent?.id == content.id {

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notchModel.temporaryNotificationContent = content
                }

                restartTemporaryTimer(duration: duration)

                /// Remove duplicate notifications from queue
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

            /// If activity is already visible just update its data
            if notchModel.liveActivityContent?.id == content.id {

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notchModel.liveActivityContent = content
                }

                return
            }

        case .hideLiveActivity(let id):

            let wasVisible = notchModel.liveActivityContent?.id == id
            activeLiveActivities.removeAll(where: { $0.id == id })

            /// If removed activity was not visible we simply
            /// clean the queue instead of triggering transitions
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

            /// Clear all queued events
            eventQueue.removeAll()
        }

        eventQueue.append(notchState)
        processQueue()
    }


    /// Sequentially processes events from the queue.
    /// Guarantees deterministic UI transitions.
    private func processQueue() {

        guard !isProcessingQueue, !eventQueue.isEmpty else { return }

        isProcessingQueue = true
        let state = eventQueue.removeFirst()

        Task {

            await executeState(state)

            if !eventQueue.isEmpty {
                try? await Task.sleep(
                    nanoseconds: UInt64(queueDelay * 1_000_000_000)
                )
            }

            isProcessingQueue = false
            processQueue()
        }
    }


    /// Executes a single notch state change.
    /// Waits for ongoing transitions to complete.
    private func executeState(_ state: NotchState) async {

        while isTransitioning {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        switch state {

        case .showLiveActivity(let content):

            let current = notchModel.liveActivityContent
            let best = highestPriorityActivity

            /// Only display the highest priority activity
            if best?.id == content.id {
                await showLiveContentTransition(content)
            }
            else if let current, current.priority >= content.priority {
                return
            }
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


    /// Animated transition between live activities
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
                hide: {
                    withAnimation(.spring(response: 0.5)) {
                        self.notchModel.liveActivityContent = nil
                    }
                },
                show: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        self.notchModel.liveActivityContent = content
                    }
                    continuation.resume()
                }
            )
        }
    }


    /// Shows temporary notification and suspends current live activity
    private func showTemporaryTransition(
        _ content: NotchContentProtocol,
        duration: TimeInterval
    ) async {

        return await withCheckedContinuation { continuation in

            transition(
                hide: {

                    self.cancelTemporary()

                    withAnimation(.spring(response: 0.5)) {

                        if self.notchModel.liveActivityContent != nil {

                            self.suspendedActivity =
                                self.notchModel.liveActivityContent

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
                        self.restartTemporaryTimer(duration: duration)
                    }

                    continuation.resume()
                }
            )
        }
    }


    /// Hides all notch content
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
                show: {
                    continuation.resume()
                }
            )
        }
    }


    /// Maintains live activity stack and sorts by priority
    private func updateLiveActivityStack(with content: NotchContentProtocol) {

        if let index = activeLiveActivities.firstIndex(where: { $0.id == content.id }) {
            activeLiveActivities[index] = content
        } else {
            activeLiveActivities.append(content)
        }

        activeLiveActivities.sort { $0.priority > $1.priority }
    }


    /// Hides temporary notification and restores suspended activity
    func hideTemporaryNotification() {

        guard notchModel.temporaryNotificationContent != nil else { return }

        cancelTemporary()

        let contentToRestore = highestPriorityActivity

        transition(
            hide: {

                withAnimation(.spring(response: 0.5)) {
                    self.notchModel.temporaryNotificationContent = nil
                }
            },
            show: {

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.notchModel.liveActivityContent = contentToRestore
                    self.suspendedActivity = nil
                }
            }
        )
    }


    /// Dismisses the currently visible notch content.
    /// Temporary notifications collapse first; live activities are removed from the stack.
    func dismissActiveContent() {

        if notchModel.temporaryNotificationContent != nil {
            hideTemporaryNotification()
            return
        }

        guard let liveActivityID = notchModel.liveActivityContent?.id else { return }
        send(.hideLiveActivity(id: liveActivityID))
    }


    /// Generic hide/show transition helper
    private func transition(
        customDelay: TimeInterval? = nil,
        hide: @escaping () -> Void,
        show: @escaping () -> Void
    ) {

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


    /// Cancels active temporary notification timer
    private func cancelTemporary() {
        temporaryTask?.cancel()
        temporaryTask = nil
    }


    /// Restarts lifetime timer for temporary notifications.
    /// Uses a token system to ignore outdated timers.
    private func restartTemporaryTimer(duration: TimeInterval) {

        cancelTemporary()

        if duration.isInfinite { return }

        let timerID = UUID()
        temporaryTimerID = timerID

        temporaryTask = Task {

            try? await Task.sleep(
                nanoseconds: UInt64(duration * 1_000_000_000)
            )

            await MainActor.run {

                /// Ignore outdated timers
                guard self.temporaryTimerID == timerID else { return }

                self.hideTemporaryNotification()
            }
        }
    }


    /// Handles notch stroke visibility when content changes
    func handleStrokeVisibility() {

        if let content = notchModel.content {

            cachedStrokeColor = content.strokeColor
            showNotch = true

        } else {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in

                guard let self,
                      self.notchModel.content == nil else { return }

                self.cachedStrokeColor = .clear
                self.showNotch = false
            }
        }
    }
}
