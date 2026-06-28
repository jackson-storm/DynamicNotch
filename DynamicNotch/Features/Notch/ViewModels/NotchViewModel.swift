import SwiftUI
import Combine

typealias NotchScreenMetrics = (width: CGFloat, topInset: CGFloat, notchSize: CGSize?)

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var notchModel = NotchModel()
    @Published private(set) var swipeStretchProgress: CGFloat = 0
    @Published private(set) var swipeInteraction: SwipeInteraction?
    @Published private(set) var stagedNotchHeight: CGFloat = NotchModel().baseHeight
    @Published private(set) var isExpandingLiveActivityTransition = false
    @Published private(set) var isActivityPresentationHidden = false
    @Published private(set) var topInset: CGFloat = 0
    
    @Published var isLocked = false
    @Published var isHoveringScrollableContent = false
    @Published var showNotch = false
    @Published var isPressed = false
    @Published var cachedStrokeColor: Color = .clear

    private let settings: NotchSettingsProviding
    private let engine: NotchEngine
    private let screenMetricsProvider: (any NotchSettingsProviding) -> NotchScreenMetrics?
    
    private var cancellables = Set<AnyCancellable>()
    private var expansionTransitionTask: Task<Void, Never>?
    private var swipeStretchResetWorkItem: DispatchWorkItem?
    private var isClosingHeightStaged = false

    var animations: NotchAnimations {
        engine.animations
    }

    var surfaceSizeAnimation: Animation? {
        isSwipeInteractionActive ? nil : animations.contentUpdate
    }

    var displayedContent: NotchContentProtocol? {
        displayedNotchModel.content
    }

    var displayedPresentationID: String? {
        displayedNotchModel.presentationID
    }

    var isDisplayingExpandedLiveActivity: Bool {
        displayedNotchModel.isPresentingExpandedLiveActivity
    }

    var shouldRenderStroke: Bool {
        displayedContent != nil || isHoldingStrokeAfterContentHide
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
        guard !isActivityPresentationHidden else { return false }
        return engine.canExpandActiveLiveActivity
    }
    
    var shouldExpandActiveContentOnClick: Bool {
        settings.isNotchTapToExpandEnabled &&
        settings.notchExpandInteraction == .click &&
        canExpandActiveLiveActivity
    }

    var shouldExpandActiveContentOnPressAndHold: Bool {
        settings.isNotchTapToExpandEnabled &&
        settings.notchExpandInteraction == .pressAndHold &&
        canExpandActiveLiveActivity
    }

    var shouldExpandActiveContentOnHover: Bool {
        settings.isNotchTapToExpandEnabled &&
        settings.notchExpandInteraction == .hover &&
        canExpandActiveLiveActivity
    }

    var notchExpandInteraction: NotchExpandInteraction {
        settings.notchExpandInteraction
    }

    var shouldCollapseActiveContentOnHoverLeaves: Bool {
        settings.notchCollapseInteraction == .hoverLeaves &&
        isDisplayingExpandedLiveActivity
    }

    var notchPressHoldDuration: TimeInterval {
        settings.notchPressHoldDuration
    }

    var notchHoverExpandDelay: TimeInterval {
        settings.notchPressHoldDuration
    }
    
    var canRestoreDismissedContent: Bool {
        engine.canRestoreDismissedContent
    }

    var canOpenActiveWindowLink: Bool {
        guard !isActivityPresentationHidden else { return false }
        return engine.canOpenActiveWindowLink
    }
    
    var canDismissWithMouseDrag: Bool {
        settings.isNotchMouseDragGesturesEnabled &&
        settings.isNotchSwipeDismissEnabled &&
        !isActivityPresentationHidden &&
        notchModel.content != nil &&
        (notchModel.content?.id != NotchContentRegistry.HomePage.active.id || notchModel.isLiveActivityExpanded)
    }
    
    var canRestoreWithMouseDrag: Bool {
        settings.isNotchMouseDragGesturesEnabled &&
        settings.isNotchSwipeRestoreEnabled &&
        canRestoreDismissedContent
    }
    
    var canDismissWithTrackpadSwipe: Bool {
        settings.isNotchTrackpadSwipeGesturesEnabled &&
        settings.isNotchSwipeDismissEnabled &&
        !isActivityPresentationHidden &&
        notchModel.content != nil &&
        (notchModel.content?.id != NotchContentRegistry.HomePage.active.id || notchModel.isLiveActivityExpanded)
    }
    
    var canRestoreWithTrackpadSwipe: Bool {
        settings.isNotchTrackpadSwipeGesturesEnabled &&
        settings.isNotchSwipeRestoreEnabled &&
        canRestoreDismissedContent
    }
    
    var interactiveNotchSize: CGSize {
        let model = displayedNotchModel
        let baseSize = model.size
        let progress = easedSwipeStretchProgress
        
        switch swipeInteraction {
        case .dismiss:
            if model.isPresentingExpandedLiveActivity || baseSize.height > model.baseHeight + 1 {
                let heightCompression = min(
                    max(baseSize.height * SwipeFeedbackMetrics.expandedDismissHeightFactor, SwipeFeedbackMetrics.expandedDismissMinimumHeight),
                    SwipeFeedbackMetrics.expandedDismissMaximumHeight
                )
                
                let widthExpansion = baseSize.width * SwipeFeedbackMetrics.expandedDismissWidthExpansionFactor
                
                return CGSize(
                    width: baseSize.width + (widthExpansion * progress),
                    height: max(model.baseHeight, baseSize.height - (heightCompression * progress))
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
        let model = displayedNotchModel
        let baseCornerRadius = model.cornerRadius
        let progress = easedSwipeStretchProgress
        
        switch swipeInteraction {
        case .dismiss:
            if model.isPresentingExpandedLiveActivity || model.size.height > model.baseHeight + 1 {
                let isHeightGreater = model.size.height > model.baseHeight
                let widthDiff = max(0, model.size.width - model.baseWidth)
                let widthFactor = widthDiff / model.baseWidth
                let topProgress = isHeightGreater ? (SwipeFeedbackMetrics.dismissTopCornerRadiusReduction * progress * widthFactor) : 0
                
                return (
                    top: max(0, baseCornerRadius.top - topProgress),
                    bottom: max(
                        baseCornerRadius.top,
                        baseCornerRadius.bottom - (SwipeFeedbackMetrics.expandedDismissCornerRadiusReduction * progress)
                    )
                )
            }
            
            return baseCornerRadius
            
        case .restore:
            let isHeightGreater = model.size.height > model.baseHeight
            let widthDiff = max(0, model.size.width - model.baseWidth)
            let widthFactor = widthDiff / model.baseWidth
            let topProgress = isHeightGreater ? (SwipeFeedbackMetrics.restoreTopCornerRadiusExpansion * progress * widthFactor) : 0
            
            return (
                top: baseCornerRadius.top + topProgress,
                bottom: baseCornerRadius.bottom + (SwipeFeedbackMetrics.restoreCornerRadiusExpansion * progress)
            )
            
        case nil:
            return baseCornerRadius
        }
    }
    
    var dynamicIslandCornerRadius: CGFloat {
        let height = presentedNotchSize.height
        if isDisplayingExpandedLiveActivity {
            if let customizable = displayedContent as? DynamicIslandCustomizable {
                return customizable.expandedDynamicIslandCornerRadius(baseHeight: height)
            }
            return height * 0.2
        } else {
            if let customizable = displayedContent as? DynamicIslandCustomizable {
                return customizable.dynamicIslandCornerRadius(baseHeight: height)
            }
            return height * 0.5
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
        self.screenMetricsProvider = screenMetricsProvider ?? { settings in
            NSScreen.metrics(for: settings)
        }
        self.engine = engine ?? NotchEngine(
            animations: { [weak settings] in
                if let animations {
                    return animations
                }
                guard let settings else { return .default }
                let isDynamic = NSScreen.metrics(for: settings)?.topInset == 0
                return .preset(settings.notchAnimationPreset, isDynamicIsland: isDynamic)
            },
            hideDelay: hideDelay,
            queueDelay: queueDelay
        )
        updateDimensions()
        bindEngine()
    }

    func updateDimensions() {
        guard let screenMetrics = screenMetricsProvider(settings) else {
            return
        }
        
        self.topInset = screenMetrics.topInset
        
        let screenWidth = screenMetrics.width
        let baseScreenWidth: CGFloat = 1440.0
        let scale = max(0.35, screenWidth / baseScreenWidth)
        
        let isDynamicIsland = screenMetrics.topInset == 0
        let widthOffset = CGFloat(isDynamicIsland ? settings.dynamicIslandWidth : settings.notchWidth)
        let heightOffset = CGFloat(isDynamicIsland ? settings.dynamicIslandHeight : settings.notchHeight)
        let baseHeightAdjustment: CGFloat = isDynamicIsland ? -3 : 0
        
        if let notchSize = screenMetrics.notchSize {
            let baseWidth = notchSize.width + 14.scaled(by: scale) + widthOffset
            let finalWidth = isDynamicIsland ? baseWidth * 0.85 : baseWidth
            
            engine.updateBaseGeometry(
                width: finalWidth,
                height: notchSize.height + heightOffset + baseHeightAdjustment,
                scale: scale,
                isDynamicIsland: isDynamicIsland
            )
            
        } else {
            let baseWidthValue: CGFloat = isDynamicIsland ? 110 : 190
            
            engine.updateBaseGeometry(
                width: (baseWidthValue * scale) + widthOffset,
                height: (25 * scale) + heightOffset + baseHeightAdjustment,
                scale: scale,
                isDynamicIsland: isDynamicIsland
            )
        }
    }
    
    func send(_ notchState: NotchState) {
        engine.send(notchState)
    }

    func setActivityPresentationHidden(_ isHidden: Bool) {
        guard isActivityPresentationHidden != isHidden else { return }

        resetSwipeStretch()

        withAnimation(animations.notchVisibility) {
            isActivityPresentationHidden = isHidden
        }
    }
    
    func hideTemporaryNotification() {
        engine.hideTemporaryNotification()
    }
    
    func dismissActiveContent() {
        if notchModel.isLiveActivityExpanded {
            engine.handleOutsideClick()
            return
        }
        
        if notchModel.liveActivityContent?.id == NotchContentRegistry.HomePage.active.id {
            return
        }
        
        engine.dismissActiveContent()
    }
    
    func restoreDismissedContent() {
        engine.restoreDismissedContent()
    }

    func openActiveWindowLink() {
        engine.openActiveWindowLink()
    }
    
    func updateSwipeStretch(for interaction: SwipeInteraction, progress: CGFloat) {
        swipeStretchResetWorkItem?.cancel()
        swipeStretchResetWorkItem = nil

        let clampedProgress = max(progress, 0)
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
        guard settings.isNotchTapToExpandEnabled,
              canExpandActiveLiveActivity else { return }

        performActiveLiveActivityExpansion()
    }

    func expandActiveLiveActivity() {
        guard canExpandActiveLiveActivity else { return }

        performActiveLiveActivityExpansion()
    }

    private func performActiveLiveActivityExpansion() {
        expansionTransitionTask?.cancel()
        isExpandingLiveActivityTransition = true

        expansionTransitionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: ExpansionTransitionTiming.preparationDelay)
            guard let self, !Task.isCancelled else { return }

            self.engine.handleActiveContentTap()

            try? await Task.sleep(nanoseconds: ExpansionTransitionTiming.resetDelay)
            guard !Task.isCancelled else { return }

            self.isExpandingLiveActivityTransition = false
            self.expansionTransitionTask = nil
        }
    }
    
    func handleOutsideClick() {
        engine.handleOutsideClick()
    }
    
    func handleStrokeVisibility() {
        engine.handleStrokeVisibility()
    }
    
    var easedSwipeStretchProgress: CGFloat {
        (1.5 * swipeStretchProgress) / (0.5 + swipeStretchProgress)
    }

    private var isHoldingStrokeAfterContentHide: Bool {
        showNotch &&
        displayedContent == nil &&
        notchModel.content == nil
    }

    private var displayedNotchModel: NotchModel {
        if isLocked {
            var model = notchModel
            model.temporaryNotificationContent = nil
            if model.liveActivityContent?.id != NotchContentRegistry.LockScreen.activity.id {
                model.liveActivityContent = nil
                model.isLiveActivityExpanded = false
            }
            return model
        }

        guard isActivityPresentationHidden else {
            return notchModel
        }

        var model = notchModel
        model.liveActivityContent = nil
        model.isLiveActivityExpanded = false
        return model
    }

    func contentTransition(notchWidth: CGFloat, notchHeight: CGFloat, baseHeight: CGFloat, isExpandedPresentation: Bool, isCompactRemovalForExpansion: Bool = false) -> AnyTransition {

        let baseTransition = AnyTransition.notchContent(
            notchWidth: notchWidth,
            notchHeight: notchHeight,
            baseHeight: baseHeight,
            isExpandedPresentation: isExpandedPresentation,
            isCompactRemovalForExpansion: isCompactRemovalForExpansion
        )

        if isExpandedPresentation {
            return .asymmetric(
                insertion: baseTransition.animation(animations.expandLiveActivityContentTransition),
                removal: baseTransition.animation(animations.closeLiveActivityContentTransition)
            )
        } else {
            return baseTransition.animation(animations.openContentTransition)
        }
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

        NotificationCenter.default.publisher(for: .notchContentPrioritiesDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.engine.refreshLiveActivityPriorities()
            }
            .store(in: &cancellables)
    }

    private func scheduleStagedHeightUpdate(to targetHeight: CGFloat) {
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

        isClosingHeightStaged = false
        applyStagedHeight(targetHeight, animated: true)
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
}

private enum ExpansionTransitionTiming {
    static let preparationDelay: UInt64 = 16_000_000
    static let resetDelay: UInt64 = 120_000_000
}
