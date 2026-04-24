import SwiftUI
import Combine

typealias NotchScreenMetrics = (width: CGFloat, topInset: CGFloat)

enum NotchSwipeInteraction {
    case dismiss
    case restore
}

private enum SwipeFeedbackMetrics {
    static let restoreHeightExpansion: CGFloat = 10
    static let collapsedDismissWidthFactor: CGFloat = 0.18
    static let collapsedDismissMinimumWidth: CGFloat = 28
    static let collapsedDismissMaximumWidth: CGFloat = 44
    static let expandedDismissHeightFactor: CGFloat = 0.16
    static let expandedDismissMinimumHeight: CGFloat = 12
    static let expandedDismissMaximumHeight: CGFloat = 28
    static let restoreCornerRadiusExpansion: CGFloat = 4
    static let expandedDismissCornerRadiusReduction: CGFloat = 4
    static let dismissBlurRadius: CGFloat = 7
    static let restoreBlurRadius: CGFloat = 4
    static let dismissOpacityReduction: Double = 0.8
    static let restoreOpacityReduction: Double = 0.5
}

private enum SurfaceResizeMetrics {
    static let heightLeadDeltaFactor: CGFloat = 0.24
    static let heightLeadDeltaMinimum: CGFloat = 6
    static let heightLeadDeltaMaximum: CGFloat = 28
    static let heightFollowUpDelay: TimeInterval = 0.1
}

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var notchModel = NotchModel()
    @Published private(set) var swipeStretchProgress: CGFloat = 0
    @Published private(set) var swipeInteraction: NotchSwipeInteraction?
    @Published private(set) var stagedNotchHeight: CGFloat = NotchModel().baseHeight
    
    @Published var showNotch = false
    @Published var isPressed = false
    @Published var cachedStrokeColor: Color = .clear

    private let settings: NotchSettingsProviding
    private let engine: NotchEngine
    private let screenMetricsProvider: (any NotchSettingsProviding) -> NotchScreenMetrics?
    private var cancellables = Set<AnyCancellable>()
    private var stagedHeightTask: Task<Void, Never>?
    private var swipeStretchResetWorkItem: DispatchWorkItem?
    private var isClosingHeightStaged = false

    var animations: NotchAnimations {
        engine.animations
    }

    var surfaceSizeAnimation: Animation? {
        isSwipeInteractionActive ? nil : animations.contentUpdate
    }

    var presentedNotchSize: CGSize {
        let size = interactiveNotchSize

        guard !isSwipeInteractionActive, isClosingHeightStaged else {
            return size
        }

        return CGSize(
            width: size.width,
            height: stagedNotchHeight
        )
    }

    var isSwipeInteractionActive: Bool {
        swipeInteraction != nil
    }
    
    var canExpandActiveLiveActivity: Bool {
        engine.canExpandActiveLiveActivity
    }
    
    var isTapToExpandEnabled: Bool {
        settings.isNotchTapToExpandEnabled
    }
    
    var canRestoreDismissedContent: Bool {
        engine.canRestoreDismissedContent
    }
    
    var canDismissWithMouseDrag: Bool {
        settings.isNotchMouseDragGesturesEnabled &&
        settings.isNotchSwipeDismissEnabled &&
        notchModel.content != nil
    }
    
    var canRestoreWithMouseDrag: Bool {
        settings.isNotchMouseDragGesturesEnabled &&
        settings.isNotchSwipeRestoreEnabled &&
        canRestoreDismissedContent
    }
    
    var canDismissWithTrackpadSwipe: Bool {
        settings.isNotchTrackpadSwipeGesturesEnabled &&
        settings.isNotchSwipeDismissEnabled &&
        notchModel.content != nil
    }
    
    var canRestoreWithTrackpadSwipe: Bool {
        settings.isNotchTrackpadSwipeGesturesEnabled &&
        settings.isNotchSwipeRestoreEnabled &&
        canRestoreDismissedContent
    }
    
    var interactiveNotchSize: CGSize {
        let baseSize = notchModel.size
        let progress = easedSwipeStretchProgress
        
        switch swipeInteraction {
        case .dismiss:
            if notchModel.isPresentingExpandedLiveActivity {
                let heightCompression = min(
                    max(baseSize.height * SwipeFeedbackMetrics.expandedDismissHeightFactor, SwipeFeedbackMetrics.expandedDismissMinimumHeight),
                    SwipeFeedbackMetrics.expandedDismissMaximumHeight
                )
                
                return CGSize(
                    width: baseSize.width,
                    height: max(notchModel.baseHeight, baseSize.height - (heightCompression * progress))
                )
            }
            
            let widthCompression = min(
                max(baseSize.width * SwipeFeedbackMetrics.collapsedDismissWidthFactor, SwipeFeedbackMetrics.collapsedDismissMinimumWidth),
                SwipeFeedbackMetrics.collapsedDismissMaximumWidth
            )
            
            return CGSize(
                width: max(baseSize.height, baseSize.width - (widthCompression * progress)),
                height: baseSize.height
            )
            
        case .restore:
            return CGSize(
                width: baseSize.width,
                height: baseSize.height + (SwipeFeedbackMetrics.restoreHeightExpansion * progress)
            )
            
        case nil:
            return baseSize
        }
    }
    
    var interactiveCornerRadius: (top: CGFloat, bottom: CGFloat) {
        let baseCornerRadius = notchModel.cornerRadius
        let progress = easedSwipeStretchProgress
        
        switch swipeInteraction {
        case .dismiss:
            if notchModel.isPresentingExpandedLiveActivity {
                return (
                    top: baseCornerRadius.top,
                    bottom: max(
                        baseCornerRadius.top,
                        baseCornerRadius.bottom - (SwipeFeedbackMetrics.expandedDismissCornerRadiusReduction * progress)
                    )
                )
            }
            
            return baseCornerRadius
            
        case .restore:
            return (
                top: baseCornerRadius.top,
                bottom: baseCornerRadius.bottom + (SwipeFeedbackMetrics.restoreCornerRadiusExpansion * progress)
            )
            
        case nil:
            return baseCornerRadius
        }
    }
    
    var contentResizeBlurRadius: CGFloat {
        let progress = easedSwipeStretchProgress
        
        switch swipeInteraction {
        case .dismiss:
            return SwipeFeedbackMetrics.dismissBlurRadius * progress
            
        case .restore:
            return SwipeFeedbackMetrics.restoreBlurRadius * progress
            
        case nil:
            return 0
        }
    }
    
    var contentResizeOpacity: Double {
        let progress = Double(easedSwipeStretchProgress)
        
        switch swipeInteraction {
        case .dismiss:
            return max(0, 1 - (SwipeFeedbackMetrics.dismissOpacityReduction * progress))
            
        case .restore:
            return max(0, 1 - (SwipeFeedbackMetrics.restoreOpacityReduction * progress))
            
        case nil:
            return 1
        }
    }
    
    
    init(
        settings: NotchSettingsProviding,
        animations: NotchAnimations? = nil,
        hideDelay: TimeInterval? = nil,
        queueDelay: TimeInterval? = nil,
        engine: NotchEngine? = nil,
        screenMetricsProvider: (((any NotchSettingsProviding) -> NotchScreenMetrics?))? = nil
    ) {
        self.settings = settings
        self.engine = engine ?? NotchEngine(
            animations: {
                animations ?? .preset(settings.notchAnimationPreset)
            },
            hideDelay: hideDelay,
            queueDelay: queueDelay
        )
        self.screenMetricsProvider = screenMetricsProvider ?? { settings in
            NSScreen.metrics(for: settings)
        }
        updateDimensions()
        bindEngine()
    }

    func updateDimensions() {
        guard let screenMetrics = screenMetricsProvider(settings) else {
            return
        }
        
        let screenWidth = screenMetrics.width
        let topInset = screenMetrics.topInset
        let baseScreenWidth: CGFloat = 1440.0
        let scale = max(0.35, screenWidth / baseScreenWidth)
        
        let widthOffset = CGFloat(settings.notchWidth)
        let heightOffset = CGFloat(settings.notchHeight)
        
        if topInset > 0 {
            engine.updateBaseGeometry(
                width: (190 * scale) + widthOffset,
                height: topInset + heightOffset,
                scale: scale
            )
        } else {
            engine.updateBaseGeometry(
                width: (190 * scale) + widthOffset,
                height: (25 * scale) + heightOffset,
                scale: scale
            )
        }
    }
    
    func send(_ notchState: NotchState) {
        engine.send(notchState)
    }
    
    func hideTemporaryNotification() {
        engine.hideTemporaryNotification()
    }
    
    func dismissActiveContent() {
        if notchModel.isLiveActivityExpanded,
           notchModel.liveActivityContent?.id == TimerNotchContent.activityID {
            engine.handleOutsideClick()
            return
        }
        
        engine.dismissActiveContent()
    }
    
    func restoreDismissedContent() {
        engine.restoreDismissedContent()
    }
    
    func updateSwipeStretch(for interaction: NotchSwipeInteraction, progress: CGFloat) {
        swipeStretchResetWorkItem?.cancel()
        swipeStretchResetWorkItem = nil

        let clampedProgress = min(max(progress, 0), 1)
        guard swipeInteraction != interaction || abs(swipeStretchProgress - clampedProgress) > 0.001 else {
            return
        }

        swipeInteraction = interaction
        swipeStretchProgress = clampedProgress
    }
    
    func resetSwipeStretch() {
        guard swipeStretchProgress > 0 || swipeInteraction != nil else { return }

        swipeStretchResetWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.applySwipeStretchReset()
        }
        swipeStretchResetWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }

    private func applySwipeStretchReset() {
        swipeStretchResetWorkItem = nil
        guard swipeStretchProgress > 0 || swipeInteraction != nil else { return }

        withAnimation(animations.stretchReset) {
            swipeStretchProgress = 0
            swipeInteraction = nil
        }
    }
    
    func handleActiveContentTap() {
        guard settings.isNotchTapToExpandEnabled else { return }
        engine.handleActiveContentTap()
    }
    
    func handleOutsideClick() {
        engine.handleOutsideClick()
    }
    
    func handleStrokeVisibility() {
        engine.handleStrokeVisibility()
    }
    
    private var easedSwipeStretchProgress: CGFloat {
        1 - pow(1 - swipeStretchProgress, 2)
    }
    
    func contentTransition(notchWidth: CGFloat, notchHeight: CGFloat, baseHeight: CGFloat, isExpandedPresentation: Bool) -> AnyTransition {
        .dynamicIslandContent(
            notchWidth: notchWidth,
            notchHeight: notchHeight,
            baseHeight: baseHeight,
            isExpandedPresentation: isExpandedPresentation
        )
        .animation(animations.contentTransition)
    }
    
    private func bindEngine() {
        notchModel = engine.notchModel
        showNotch = engine.showNotch
        cachedStrokeColor = engine.cachedStrokeColor
        stagedNotchHeight = engine.notchModel.size.height
        isClosingHeightStaged = false
        
        engine.$notchModel
            .dropFirst()
            .sink { [weak self] in
                self?.scheduleStagedHeightUpdate(to: $0.size.height)
                self?.notchModel = $0
            }
            .store(in: &cancellables)
        
        engine.$showNotch
            .sink { [weak self] in
                self?.showNotch = $0
            }
            .store(in: &cancellables)
        
        engine.$cachedStrokeColor
            .sink { [weak self] in
                self?.cachedStrokeColor = $0
            }
            .store(in: &cancellables)
    }

    private func scheduleStagedHeightUpdate(to targetHeight: CGFloat) {
        stagedHeightTask?.cancel()

        guard !isSwipeInteractionActive else {
            isClosingHeightStaged = false
            stagedNotchHeight = targetHeight
            return
        }

        let currentHeight = stagedNotchHeight

        guard abs(currentHeight - targetHeight) > 0.5 else {
            isClosingHeightStaged = false
            stagedNotchHeight = targetHeight
            return
        }

        guard targetHeight < currentHeight else {
            isClosingHeightStaged = false
            stagedNotchHeight = targetHeight
            return
        }

        isClosingHeightStaged = true

        let leadHeight = intermediateHeight(from: currentHeight, to: targetHeight)

        applyStagedHeight(leadHeight, animated: true)

        guard abs(leadHeight - targetHeight) > 0.5 else {
            isClosingHeightStaged = false
            stagedNotchHeight = targetHeight
            return
        }

        stagedHeightTask = Task { [weak self] in
            try? await Task.sleep(
                nanoseconds: UInt64(SurfaceResizeMetrics.heightFollowUpDelay * 1_000_000_000)
            )

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self?.applyStagedHeight(targetHeight, animated: true)
                self?.isClosingHeightStaged = false
            }
        }
    }

    private func applyStagedHeight(_ targetHeight: CGFloat, animated: Bool) {
        guard animated, let animation = surfaceSizeAnimation else {
            stagedNotchHeight = targetHeight
            return
        }

        withAnimation(animation) {
            stagedNotchHeight = targetHeight
        }
    }

    private func intermediateHeight(from currentHeight: CGFloat, to targetHeight: CGFloat) -> CGFloat {
        let delta = targetHeight - currentHeight
        let clampedLeadDelta = min(
            abs(delta),
            max(
                abs(delta) * SurfaceResizeMetrics.heightLeadDeltaFactor,
                SurfaceResizeMetrics.heightLeadDeltaMinimum
            ),
            SurfaceResizeMetrics.heightLeadDeltaMaximum
        )

        return currentHeight + (delta.sign == .minus ? -clampedLeadDelta : clampedLeadDelta)
    }
}
