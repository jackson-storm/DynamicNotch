import SwiftUI
import Combine

typealias NotchScreenMetrics = (width: CGFloat, topInset: CGFloat, notchSize: CGSize?)

@MainActor
final class NotchViewModel: ObservableObject {
    @Published private(set) var notchModel = NotchModel()
    @Published private(set) var stagedNotchHeight: CGFloat = NotchModel().baseHeight
    @Published private(set) var isExpandingLiveActivityTransition = false
    @Published private(set) var isActivityPresentationHidden = false
    @Published private(set) var hasDisplayedContent = false
    @Published private(set) var topInset: CGFloat = 0
    
    @Published var isLocked = false
    @Published var isHoveringScrollableContent = false
    @Published var isScrubbingContent = false
    @Published var showNotch = false
    @Published var isPressed = false
    @Published var cachedStrokeColor: Color = .clear
    @Published var pressScale: CGFloat = 1.0
    
    @Published var focusCloseStretchWidth: CGFloat = 0.0
    @Published var focusCloseStretchHeight: CGFloat = 0.0
    
    @Published var notchPulseWidth: CGFloat = 0.0
    @Published var notchPulseHeight: CGFloat = 0.0

    let gestureCoordinator: GestureCoordinator

    private let settings: NotchSettingsProviding
    private let engine: NotchEngine
    private let screenMetricsProvider: (any NotchSettingsProviding) -> NotchScreenMetrics?
    
    private var cancellables = Set<AnyCancellable>()
    private var expansionTransitionTask: Task<Void, Never>?
    private var restoreContentWorkItem: DispatchWorkItem?
    private var notchPulseResetWorkItem: DispatchWorkItem?
    private var isClosingHeightStaged = false
    private var isFocusCloseAnimating = false

    var swipeStretchProgress: CGFloat {
        gestureCoordinator.swipeStretchProgress
    }

    var verticalSwipeStretchProgress: CGFloat {
        gestureCoordinator.verticalSwipeStretchProgress
    }

    var horizontalSwipeStretchProgress: CGFloat {
        gestureCoordinator.horizontalSwipeStretchProgress
    }

    var swipeInteraction: SwipeInteraction? {
        gestureCoordinator.swipeInteraction
    }

    var isSwipeInteractionActive: Bool {
        gestureCoordinator.isSwipeInteractionActive
    }

    var easedSwipeStretchProgress: CGFloat {
        gestureCoordinator.easedSwipeStretchProgress
    }

    var animations: NotchAnimations {
        engine.animations
    }

    var surfaceSizeAnimation: Animation? {
        isSwipeInteractionActive ? nil : animations.updateContent
    }

    var displayedContent: NotchContentProtocol? {
        displayedNotchModel.content
    }

    var displayedPresentationID: String? {
        displayedNotchModel.presentationID
    }

    var isDynamicIsland: Bool {
        topInset == 0
    }

    var isDisplayingExpandedLiveActivity: Bool {
        displayedNotchModel.isPresentingExpandedLiveActivity
    }

    var isExpandedPresentation: Bool {
        isDisplayingExpandedLiveActivity || displayedBaseNotchSize.height > notchModel.baseHeight + 1
    }

    var hasRealDisplayedContent: Bool {
        displayedContent != nil
    }

    var shouldRenderStroke: Bool {
        hasRealDisplayedContent || isHoldingStrokeAfterContentHide
    }

    var shouldApplyPressScale: Bool {
        guard !isSwipeInteractionActive else { return false }
        guard let content = displayedContent else { return true }
        guard !isDisplayingExpandedLiveActivity else { return false }

        return content.allowsPressScaleEffect && content.allowsCompactPressScaleEffect
    }

    var displayedBaseNotchSize: CGSize {
        displayedNotchModel.size
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
    
    var canExpandActiveLiveActivity: Bool {
        guard (!isActivityPresentationHidden || isLocked) || notchModel.temporaryNotificationContent != nil else { return false }
        if isLocked {
            guard notchModel.temporaryNotificationContent != nil || notchModel.liveActivityContent?.id == NotchContentRegistry.LockScreen.activity.id else {
                return false
            }
        }
        guard hasRealDisplayedContent else { return false }
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
        guard !isLocked else { return false }
        return engine.canRestoreDismissedContent
    }

    var canOpenActiveWindowLink: Bool {
        guard !isLocked else { return false }
        guard !isActivityPresentationHidden || notchModel.temporaryNotificationContent != nil else { return false }
        guard hasRealDisplayedContent else { return false }
        return engine.canOpenActiveWindowLink
    }
    
    var canDismissWithMouseDrag: Bool {
        gestureCoordinator.canDismissWithMouseDrag(
            isMouseDragEnabled: settings.isNotchMouseDragGesturesEnabled,
            isSwipeDismissEnabled: settings.isNotchSwipeDismissEnabled,
            isLocked: isLocked,
            isActivityPresentationHidden: isActivityPresentationHidden,
            hasTemporaryNotification: notchModel.temporaryNotificationContent != nil,
            hasRealDisplayedContent: hasRealDisplayedContent
        )
    }
    
    var canRestoreWithMouseDrag: Bool {
        gestureCoordinator.canRestoreWithMouseDrag(
            isMouseDragEnabled: settings.isNotchMouseDragGesturesEnabled,
            isSwipeRestoreEnabled: settings.isNotchSwipeRestoreEnabled,
            isLocked: isLocked,
            isLiveActivityExpanded: isExpandedPresentation,
            canRestoreDismissedContent: canRestoreDismissedContent,
            hasRealDisplayedContent: hasRealDisplayedContent
        )
    }
    
    var canDismissWithTrackpadSwipe: Bool {
        gestureCoordinator.canDismissWithTrackpadSwipe(
            isTrackpadSwipeEnabled: settings.isNotchTrackpadSwipeGesturesEnabled,
            isSwipeDismissEnabled: settings.isNotchSwipeDismissEnabled,
            isLocked: isLocked,
            isActivityPresentationHidden: isActivityPresentationHidden,
            hasTemporaryNotification: notchModel.temporaryNotificationContent != nil,
            hasRealDisplayedContent: hasRealDisplayedContent
        )
    }
    
    var canRestoreWithTrackpadSwipe: Bool {
        gestureCoordinator.canRestoreWithTrackpadSwipe(
            isTrackpadSwipeEnabled: settings.isNotchTrackpadSwipeGesturesEnabled,
            isSwipeRestoreEnabled: settings.isNotchSwipeRestoreEnabled,
            isLocked: isLocked,
            isLiveActivityExpanded: isExpandedPresentation,
            canRestoreDismissedContent: canRestoreDismissedContent,
            hasRealDisplayedContent: hasRealDisplayedContent
        )
    }

    var canDismissWithHorizontalTrackpadSwipe: Bool {
        gestureCoordinator.canDismissWithHorizontalTrackpadSwipe(
            canDismissWithTrackpadSwipe: canDismissWithTrackpadSwipe,
            isDisplayingExpandedLiveActivity: isDisplayingExpandedLiveActivity,
            notchHeight: notchModel.size.height,
            baseHeight: notchModel.baseHeight
        )
    }

    var canDismissWithHorizontalMouseDrag: Bool {
        gestureCoordinator.canDismissWithHorizontalMouseDrag(
            canDismissWithMouseDrag: canDismissWithMouseDrag
        )
    }

    var isMouseDragStretchEnabled: Bool {
        gestureCoordinator.canStretchWithMouseDrag(
            isMouseDragEnabled: settings.isNotchMouseDragGesturesEnabled,
            isSwipeGesturesEnabled: settings.isNotchSwipeDismissEnabled || settings.isNotchSwipeRestoreEnabled,
            isLocked: isLocked
        )
    }

    var isTrackpadSwipeStretchEnabled: Bool {
        gestureCoordinator.canStretchWithTrackpadSwipe(
            isTrackpadSwipeEnabled: settings.isNotchTrackpadSwipeGesturesEnabled,
            isSwipeGesturesEnabled: settings.isNotchSwipeDismissEnabled || settings.isNotchSwipeRestoreEnabled,
            isLocked: isLocked
        )
    }
    
    var isNotchHoverHapticEnabled: Bool {
        settings.isNotchHoverHapticEnabled
    }
    
    var interactiveNotchSize: CGSize {
        gestureCoordinator.interactiveNotchSize(
            model: displayedNotchModel,
            focusCloseStretchWidth: focusCloseStretchWidth,
            focusCloseStretchHeight: focusCloseStretchHeight,
            notchPulseWidth: notchPulseWidth,
            notchPulseHeight: notchPulseHeight
        )
    }
    
    var interactiveCornerRadius: (top: CGFloat, bottom: CGFloat) {
        let model = displayedNotchModel
        let baseCornerRadius = model.cornerRadius
        let radiusOffset = (focusCloseStretchHeight + notchPulseHeight) * 0.3
        
        return (
            top: baseCornerRadius.top + radiusOffset,
            bottom: baseCornerRadius.bottom + radiusOffset
        )
    }
    
    var dynamicIslandCornerRadius: CGFloat {
        let height = swipeInteraction != nil ? displayedNotchModel.size.height : presentedNotchSize.height
        let baseRadius: CGFloat
        
        if isDisplayingExpandedLiveActivity {
            if let customizable = displayedContent {
                baseRadius = customizable.expandedDynamicIslandCornerRadius(baseHeight: height)
            } else {
                baseRadius = height * 0.2
            }
        } else {
            if let customizable = displayedContent {
                baseRadius = customizable.dynamicIslandCornerRadius(baseHeight: height)
            } else {
                baseRadius = height * 0.5
            }
        }
        
        let model = displayedNotchModel
        let expansion = gestureCoordinator.dynamicIslandCornerRadiusExpansion(
            isDynamicIsland: isDynamicIsland,
            modelHeight: model.size.height,
            baseHeight: model.baseHeight
        )
        return baseRadius + expansion
    }
    
    var contentResizeBlurRadius: CGFloat {
        gestureCoordinator.contentResizeBlurRadius()
    }
    
    var contentResizeOpacity: Double {
        gestureCoordinator.contentResizeOpacity()
    }
    
    init(
        settings: NotchSettingsProviding,
        animations: NotchAnimations? = nil,
        hideDelay: TimeInterval? = nil,
        queueDelay: TimeInterval? = nil,
        engine: NotchEngine? = nil,
        gestureCoordinator: GestureCoordinator? = nil,
        screenMetricsProvider: (((any NotchSettingsProviding) -> NotchScreenMetrics?))? = nil
    ) {
        self.settings = settings
        self.gestureCoordinator = gestureCoordinator ?? GestureCoordinator()
        self.screenMetricsProvider = screenMetricsProvider ?? { settings in
            NSScreen.metrics(for: settings)
        }
        self.engine = engine ?? NotchEngine(
            animations: {
                animations ?? .animations
            },
            hideDelay: hideDelay,
            queueDelay: queueDelay
        )
        updateDimensions(animated: false)
        bindEngine()
    }

    func updateDimensions(animated: Bool = true) {
        guard let screenMetrics = screenMetricsProvider(settings) else {
            return
        }
        
        self.topInset = screenMetrics.topInset
        
        let screenWidth = screenMetrics.width
        let baseScreenWidth: CGFloat = 1440.0
        let scale = max(0.35, screenWidth / baseScreenWidth)
        let widthScale = scale > 1.0 ? 1.0 + (scale - 1.0) * 0.35 : scale
        
        let isDynamicIsland = screenMetrics.topInset == 0
        let widthOffset = CGFloat(settings.notchWidth) + 2
        let heightOffset = CGFloat(settings.notchHeight)
        let baseHeightAdjustment: CGFloat = isDynamicIsland ? 5 : 0
        
        let finalWidth: CGFloat
        let finalHeight: CGFloat
        
        if let notchSize = screenMetrics.notchSize {
            let baseWidth = notchSize.width + 14.scaled(by: widthScale) + widthOffset
            finalWidth = isDynamicIsland ? baseWidth * 0.85 : baseWidth
            finalHeight = notchSize.height + heightOffset + baseHeightAdjustment
        } else {
            let baseWidthValue: CGFloat = isDynamicIsland ? 90 : 190
            let baseWidth = (baseWidthValue * widthScale) + widthOffset
            finalWidth = isDynamicIsland ? baseWidth * 0.85 : baseWidth
            finalHeight = 26 + heightOffset + baseHeightAdjustment
        }
        
        let applyGeometry = {
            self.engine.updateBaseGeometry(
                width: finalWidth,
                height: finalHeight,
                scale: scale,
                isDynamicIsland: isDynamicIsland
            )
        }
        
        if animated {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85)) {
                applyGeometry()
            }
        } else {
            applyGeometry()
        }
    }
    
    func send(_ notchState: NotchState) {
        engine.send(notchState)
    }

    func setPreferredLiveActivity(id: String?) {
        engine.setPreferredLiveActivity(id: id)
    }

    func setActivityPresentationHidden(_ isHidden: Bool) {
        guard isActivityPresentationHidden != isHidden else { return }

        resetSwipeStretch()

        withAnimation(animations.notchVisibility) {
            isActivityPresentationHidden = isHidden
            hasDisplayedContent = hasRealDisplayedContent
        }
    }
    
    func hideTemporaryNotification() {
        engine.hideTemporaryNotification()
    }
    
    func dismissActiveContent() {
        if isLocked {
            resetSwipeStretch()
            return
        }

        if notchModel.isLiveActivityExpanded {
            engine.handleOutsideClick()
            return
        }
        
        engine.dismissActiveContent()
    }
    
    func restoreDismissedContent() {
        if isLocked || isExpandedPresentation || notchModel.isLiveActivityExpanded {
            resetSwipeStretch()
            return
        }

        restoreContentWorkItem?.cancel()
        restoreContentWorkItem = nil

        notchModel.isLiveActivityExpanded = false

        if swipeStretchProgress > 0 || swipeInteraction != nil {
            applySwipeStretchReset()
            let workItem = DispatchWorkItem { [weak self] in
                self?.restoreContentWorkItem = nil
                self?.notchModel.isLiveActivityExpanded = false
                self?.engine.restoreDismissedContent()
            }
            restoreContentWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: workItem)
        } else {
            notchModel.isLiveActivityExpanded = false
            engine.restoreDismissedContent()
        }
    }

    func openActiveWindowLink() {
        guard let content = notchModel.content, content.windowLink != nil else {
            engine.openActiveWindowLink()
            return
        }
        
        if notchModel.temporaryNotificationContent != nil {
            engine.openActiveWindowLink()
            engine.hideTemporaryNotification()
            return
        }
        
        let isFocus = content.id == NotchContentRegistry.Focus.active.id || content.id == NotchContentRegistry.Focus.inactive.id
        if isFocus && settings.isCloseAtFocusLiveActivityEnabled {
            triggerFocusCloseAnimation(for: content.id) { [weak self] in
                self?.engine.openActiveWindowLink()
                self?.send(.hideLiveActivity(id: content.id))
            }
        } else {
            engine.openActiveWindowLink()
        }
    }

    func triggerFocusCloseAnimation(for id: String, completion: @escaping () -> Void) {
        guard !isFocusCloseAnimating else {
            completion()
            return
        }
        isFocusCloseAnimating = true
        
        let currentWidth = presentedNotchSize.width
        let currentHeight = presentedNotchSize.height
        
        let compressWidth = -max(20, currentWidth * 0.2)
        let stretchHeight = max(40, currentHeight * 0.2)
        
        withAnimation(animations.focusDismissBounce) {
            self.focusCloseStretchWidth = compressWidth
            self.focusCloseStretchHeight = stretchHeight
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(self.animations.focusDismissBounce) {
                self.focusCloseStretchWidth = 0
                self.focusCloseStretchHeight = 0
            }
            completion()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.isFocusCloseAnimating = false
            }
        }
    }
    
    func pulseNotch(widthOffset: CGFloat = 30.0, heightOffset: CGFloat = 10.0) {
        notchPulseResetWorkItem?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55, blendDuration: 0)) {
            self.notchPulseWidth = widthOffset
            self.notchPulseHeight = heightOffset
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0)) {
                self.notchPulseWidth = 0
                self.notchPulseHeight = 0
            }
        }
        notchPulseResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
    }
    
    func updateSwipeStretch(for interaction: SwipeInteraction, progress: CGFloat) {
        gestureCoordinator.updateSwipeStretch(for: interaction, progress: progress)
    }
    
    func resetSwipeStretch() {
        gestureCoordinator.resetSwipeStretch(animation: animations.stretchReset)
    }

    private func applySwipeStretchReset() {
        gestureCoordinator.applySwipeStretchReset(animation: animations.stretchReset)
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
    
    func easedProgress(for rawProgress: CGFloat) -> CGFloat {
        gestureCoordinator.easedProgress(for: rawProgress)
    }

    private var isHoldingStrokeAfterContentHide: Bool {
        showNotch &&
        !hasRealDisplayedContent &&
        notchModel.content == nil
    }

    private var displayedNotchModel: NotchModel {
        guard isActivityPresentationHidden, !isLocked else {
            return notchModel
        }

        var model = notchModel
        model.liveActivityContent = nil
        model.isLiveActivityExpanded = false
        return model
    }

    func contentTransition(
        notchWidth: CGFloat? = nil,
        notchHeight: CGFloat,
        baseWidth: CGFloat? = nil,
        baseHeight: CGFloat,
        isExpandedPresentation: Bool
    ) -> AnyTransition {
        let width = notchWidth ?? presentedNotchSize.width
        let bWidth = baseWidth ?? notchModel.baseWidth
        let expandedTransition = AnyTransition.notchExpanded(
            notchHeight: notchHeight,
            baseHeight: baseHeight,
            isNotchlessScreen: isDynamicIsland
        )
        let compactTransition = AnyTransition.notchCompact(
            notchWidth: width,
            notchHeight: notchHeight,
            baseWidth: bWidth,
            baseHeight: baseHeight,
            isNotchlessScreen: isDynamicIsland
        )

        if isExpandedPresentation {
            return .asymmetric(
                insertion: expandedTransition.animation(animations.expandedLiveActivityContentTransition),
                removal: expandedTransition.animation(animations.collapsedLiveActivityContentTransition)
            )
        } else {
            return .asymmetric(
                insertion: compactTransition.animation(animations.showContent),
                removal: compactTransition.animation(animations.hideContent)
            )
        }
    }
    
    private func bindEngine() {
        notchModel = engine.notchModel
        showNotch = engine.showNotch
        cachedStrokeColor = engine.cachedStrokeColor
        stagedNotchHeight = engine.notchModel.size.height
        isClosingHeightStaged = false
        hasDisplayedContent = hasRealDisplayedContent

        gestureCoordinator.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        engine.$notchModel
            .dropFirst()
            .sink { [weak self] in
                guard let self else { return }
                self.scheduleStagedHeightUpdate(to: $0.size.height)
                self.notchModel = $0
                self.hasDisplayedContent = self.hasRealDisplayedContent
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
