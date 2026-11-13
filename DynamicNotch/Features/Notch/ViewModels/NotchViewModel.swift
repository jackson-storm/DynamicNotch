//
//  NotchViewModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 11/10/26.
//

import SwiftUI
import Combine

typealias NotchScreenMetrics = (width: CGFloat, topInset: CGFloat, notchSize: CGSize?)

@MainActor
final class NotchViewModel: ObservableObject, NotchCommandDispatching {
    // MARK: - Published State
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

    // MARK: - Coordinators & Dependencies
    let gestureCoordinator: GestureCoordinator
    let geometryCoordinator: NotchGeometryCoordinator
    let expansionCoordinator: NotchExpansionCoordinator
    let effectsCoordinator: NotchEffectsCoordinator

    private let settings: NotchSettingsProviding
    private let engine: NotchEngine
    private let screenMetricsProvider: (any NotchSettingsProviding) -> NotchScreenMetrics?

    private var cancellables = Set<AnyCancellable>()
    private var restoreContentWorkItem: DispatchWorkItem?

    // MARK: - Computed Properties (Animations & Content)
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
        effectsCoordinator.shouldApplyPressScale(
            isSwipeInteractionActive: isSwipeInteractionActive,
            displayedContent: displayedContent,
            isDisplayingExpandedLiveActivity: isDisplayingExpandedLiveActivity
        )
    }

    var displayedBaseNotchSize: CGSize {
        displayedNotchModel.size
    }

    var presentedNotchSize: CGSize {
        let size = interactiveNotchSize

        guard !isSwipeInteractionActive, geometryCoordinator.isClosingHeightStaged else {
            return size
        }

        return CGSize(
            width: size.width,
            height: stagedNotchHeight
        )
    }

    // MARK: - Expansion Rules & State
    var canExpandActiveLiveActivity: Bool {
        expansionCoordinator.canExpandActiveLiveActivity(
            isActivityPresentationHidden: isActivityPresentationHidden,
            isLocked: isLocked,
            hasTemporaryNotification: notchModel.temporaryNotificationContent != nil,
            liveActivityId: notchModel.liveActivityContent?.id,
            hasRealDisplayedContent: hasRealDisplayedContent,
            engineCanExpand: engine.canExpandActiveLiveActivity
        )
    }

    var shouldExpandActiveContentOnClick: Bool {
        expansionCoordinator.shouldExpandOnClick(
            isTapToExpandEnabled: settings.isNotchTapToExpandEnabled,
            expandInteraction: settings.notchExpandInteraction,
            canExpand: canExpandActiveLiveActivity
        )
    }

    var shouldExpandActiveContentOnPressAndHold: Bool {
        expansionCoordinator.shouldExpandOnPressAndHold(
            isTapToExpandEnabled: settings.isNotchTapToExpandEnabled,
            expandInteraction: settings.notchExpandInteraction,
            canExpand: canExpandActiveLiveActivity
        )
    }

    var shouldExpandActiveContentOnHover: Bool {
        expansionCoordinator.shouldExpandOnHover(
            isTapToExpandEnabled: settings.isNotchTapToExpandEnabled,
            expandInteraction: settings.notchExpandInteraction,
            canExpand: canExpandActiveLiveActivity
        )
    }

    var notchExpandInteraction: NotchExpandInteraction {
        settings.notchExpandInteraction
    }

    var shouldCollapseActiveContentOnHoverLeaves: Bool {
        expansionCoordinator.shouldCollapseOnHoverLeaves(
            collapseInteraction: settings.notchCollapseInteraction,
            isDisplayingExpandedLiveActivity: isDisplayingExpandedLiveActivity
        )
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

    // MARK: - Gesture Delegations
    private var gestureContext: GestureCoordinator.Context {
        GestureCoordinator.Context(
            settings: settings,
            isLocked: isLocked,
            isActivityPresentationHidden: isActivityPresentationHidden,
            hasTemporaryNotification: notchModel.temporaryNotificationContent != nil,
            hasRealDisplayedContent: hasRealDisplayedContent,
            isExpandedPresentation: isExpandedPresentation,
            canRestoreDismissedContent: canRestoreDismissedContent
        )
    }

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

    var canDismissWithMouseDrag: Bool {
        gestureCoordinator.canDismissWithMouseDrag(context: gestureContext)
    }

    var canRestoreWithMouseDrag: Bool {
        gestureCoordinator.canRestoreWithMouseDrag(context: gestureContext)
    }

    var canDismissWithTrackpadSwipe: Bool {
        gestureCoordinator.canDismissWithTrackpadSwipe(context: gestureContext)
    }

    var canRestoreWithTrackpadSwipe: Bool {
        gestureCoordinator.canRestoreWithTrackpadSwipe(context: gestureContext)
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
        gestureCoordinator.canStretchWithMouseDrag(context: gestureContext)
    }

    var isTrackpadSwipeStretchEnabled: Bool {
        gestureCoordinator.canStretchWithTrackpadSwipe(context: gestureContext)
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
        geometryCoordinator.interactiveCornerRadius(
            baseCornerRadius: displayedNotchModel.cornerRadius,
            focusCloseStretchHeight: focusCloseStretchHeight,
            notchPulseHeight: notchPulseHeight
        )
    }

    var dynamicIslandCornerRadius: CGFloat {
        let height = swipeInteraction != nil ? displayedNotchModel.size.height : presentedNotchSize.height
        let expansion = gestureCoordinator.dynamicIslandCornerRadiusExpansion(
            isDynamicIsland: isDynamicIsland,
            modelHeight: displayedNotchModel.size.height,
            baseHeight: displayedNotchModel.baseHeight
        )
        return geometryCoordinator.dynamicIslandCornerRadius(
            height: height,
            isDisplayingExpandedLiveActivity: isDisplayingExpandedLiveActivity,
            displayedContent: displayedContent,
            gestureExpansion: expansion
        )
    }

    var contentResizeBlurRadius: CGFloat {
        gestureCoordinator.contentResizeBlurRadius()
    }

    var contentResizeOpacity: Double {
        gestureCoordinator.contentResizeOpacity()
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

    func easedProgress(for rawProgress: CGFloat) -> CGFloat {
        gestureCoordinator.easedProgress(for: rawProgress)
    }

    // MARK: - Initialization
    init(
        settings: NotchSettingsProviding,
        animations: NotchAnimations? = nil,
        hideDelay: TimeInterval? = nil,
        queueDelay: TimeInterval? = nil,
        engine: NotchEngine? = nil,
        gestureCoordinator: GestureCoordinator? = nil,
        geometryCoordinator: NotchGeometryCoordinator? = nil,
        expansionCoordinator: NotchExpansionCoordinator? = nil,
        effectsCoordinator: NotchEffectsCoordinator? = nil,
        screenMetricsProvider: (((any NotchSettingsProviding) -> NotchScreenMetrics?))? = nil
    ) {
        self.settings = settings
        self.gestureCoordinator = gestureCoordinator ?? GestureCoordinator()
        let resolvedEngine = engine ?? NotchEngine(
            animations: {
                animations ?? .animations
            },
            hideDelay: hideDelay,
            queueDelay: queueDelay
        )
        self.engine = resolvedEngine
        self.geometryCoordinator = geometryCoordinator ?? NotchGeometryCoordinator(initialBaseHeight: resolvedEngine.notchModel.size.height)
        self.expansionCoordinator = expansionCoordinator ?? NotchExpansionCoordinator()
        self.effectsCoordinator = effectsCoordinator ?? NotchEffectsCoordinator()
        self.screenMetricsProvider = screenMetricsProvider ?? { settings in
            NSScreen.metrics(for: settings)
        }

        updateDimensions(animated: false)
        bindEngine()
    }

    // MARK: - Dimensions
    func updateDimensions(animated: Bool = true) {
        guard let screenMetrics = screenMetricsProvider(settings) else { return }

        let calculated = geometryCoordinator.calculateGeometry(
            screenMetrics: screenMetrics,
            notchWidthSetting: Double(settings.notchWidth),
            notchHeightSetting: Double(settings.notchHeight)
        )

        self.topInset = calculated.topInset
        geometryCoordinator.topInset = calculated.topInset

        let applyGeometry = {
            self.engine.updateBaseGeometry(
                width: calculated.width,
                height: calculated.height,
                scale: calculated.scale,
                isDynamicIsland: calculated.isDynamicIsland
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

    // MARK: - Effects & Animations
    func pulseNotch(widthOffset: CGFloat = 30.0, heightOffset: CGFloat = 10.0) {
        effectsCoordinator.pulseNotch(widthOffset: widthOffset, heightOffset: heightOffset)
    }

    func triggerFocusCloseAnimation(for id: String, completion: @escaping () -> Void) {
        effectsCoordinator.triggerFocusCloseAnimation(
            presentedSize: presentedNotchSize,
            animations: animations,
            completion: completion
        )
    }

    // MARK: - Expansion Actions
    func handleActiveContentTap() {
        guard settings.isNotchTapToExpandEnabled,
              canExpandActiveLiveActivity else { return }

        expansionCoordinator.performExpansion { [weak self] in
            self?.engine.handleActiveContentTap()
        }
    }

    func expandActiveLiveActivity() {
        guard canExpandActiveLiveActivity else { return }

        expansionCoordinator.performExpansion { [weak self] in
            self?.engine.handleActiveContentTap()
        }
    }

    // MARK: - Transitions
    func contentTransition(
        notchWidth: CGFloat? = nil,
        notchHeight: CGFloat,
        baseWidth: CGFloat? = nil,
        baseHeight: CGFloat,
        isExpandedPresentation: Bool
    ) -> AnyTransition {
        NotchTransitionBuilder.build(
            notchWidth: notchWidth ?? presentedNotchSize.width,
            notchHeight: notchHeight,
            baseWidth: baseWidth ?? notchModel.baseWidth,
            baseHeight: baseHeight,
            isDynamicIsland: isDynamicIsland,
            isExpandedPresentation: isExpandedPresentation,
            animations: animations
        )
    }

    // MARK: - NotchCommandDispatching & Content Actions
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

    func handleOutsideClick() {
        engine.handleOutsideClick()
    }

    func handleStrokeVisibility() {
        engine.handleStrokeVisibility()
    }

    func send(_ notchState: NotchState) {
        engine.send(notchState)
    }

    func setPreferredLiveActivity(id: String?) {
        engine.setPreferredLiveActivity(id: id)
    }

    var isHoldingStrokeAfterContentHide: Bool {
        showNotch &&
        !hasRealDisplayedContent &&
        notchModel.content == nil
    }

    var displayedNotchModel: NotchModel {
        guard isActivityPresentationHidden, !isLocked else {
            return notchModel
        }

        var model = notchModel
        model.liveActivityContent = nil
        model.isLiveActivityExpanded = false
        return model
    }

    // MARK: - Engine & Coordinator Bindings
    private func bindEngine() {
        notchModel = engine.notchModel
        showNotch = engine.showNotch
        cachedStrokeColor = engine.cachedStrokeColor
        stagedNotchHeight = engine.notchModel.size.height
        geometryCoordinator.isClosingHeightStaged = false
        hasDisplayedContent = hasRealDisplayedContent

        gestureCoordinator.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        geometryCoordinator.$stagedNotchHeight
            .dropFirst()
            .assign(to: &$stagedNotchHeight)

        geometryCoordinator.$topInset
            .dropFirst()
            .assign(to: &$topInset)

        expansionCoordinator.$isExpandingLiveActivityTransition
            .dropFirst()
            .assign(to: &$isExpandingLiveActivityTransition)

        effectsCoordinator.$focusCloseStretchWidth
            .dropFirst()
            .assign(to: &$focusCloseStretchWidth)

        effectsCoordinator.$focusCloseStretchHeight
            .dropFirst()
            .assign(to: &$focusCloseStretchHeight)

        effectsCoordinator.$notchPulseWidth
            .dropFirst()
            .assign(to: &$notchPulseWidth)

        effectsCoordinator.$notchPulseHeight
            .dropFirst()
            .assign(to: &$notchPulseHeight)

        effectsCoordinator.$pressScale
            .dropFirst()
            .assign(to: &$pressScale)

        engine.$notchModel
            .dropFirst()
            .sink { [weak self] in
                guard let self else { return }
                self.geometryCoordinator.scheduleStagedHeightUpdate(
                    to: $0.size.height,
                    isSwipeInteractionActive: self.isSwipeInteractionActive,
                    animation: self.surfaceSizeAnimation
                )
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
}
