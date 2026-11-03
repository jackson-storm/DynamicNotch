//
//  GestureCoordinator.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 11/3/26.
//

import SwiftUI
import Combine

@MainActor
final class GestureCoordinator: ObservableObject {
    @Published private(set) var swipeStretchProgress: CGFloat = 0
    @Published private(set) var verticalSwipeStretchProgress: CGFloat = 0
    @Published private(set) var horizontalSwipeStretchProgress: CGFloat = 0
    @Published private(set) var swipeInteraction: SwipeInteraction?

    private var swipeStretchResetWorkItem: DispatchWorkItem?

    var isSwipeInteractionActive: Bool {
        swipeInteraction != nil
    }

    var easedSwipeStretchProgress: CGFloat {
        easedProgress(for: swipeStretchProgress)
    }

    func easedProgress(for rawProgress: CGFloat) -> CGFloat {
        let progress = max(0, rawProgress)
        return (1.5 * progress) / (0.5 + progress)
    }

    // MARK: - Gesture Capability Checks

    func canDismissWithMouseDrag(
        isMouseDragEnabled: Bool,
        isSwipeDismissEnabled: Bool,
        isLocked: Bool,
        isActivityPresentationHidden: Bool,
        hasTemporaryNotification: Bool,
        hasRealDisplayedContent: Bool
    ) -> Bool {
        isMouseDragEnabled &&
        isSwipeDismissEnabled &&
        (!isActivityPresentationHidden || isLocked || hasTemporaryNotification) &&
        hasRealDisplayedContent
    }

    func canRestoreWithMouseDrag(
        isMouseDragEnabled: Bool,
        isSwipeRestoreEnabled: Bool,
        isLocked: Bool,
        isLiveActivityExpanded: Bool,
        canRestoreDismissedContent: Bool
    ) -> Bool {
        guard !isLocked else { return false }
        guard !isLiveActivityExpanded else { return false }
        return isMouseDragEnabled &&
        isSwipeRestoreEnabled &&
        canRestoreDismissedContent
    }

    func canDismissWithTrackpadSwipe(
        isTrackpadSwipeEnabled: Bool,
        isSwipeDismissEnabled: Bool,
        isLocked: Bool,
        isActivityPresentationHidden: Bool,
        hasTemporaryNotification: Bool,
        hasRealDisplayedContent: Bool
    ) -> Bool {
        isTrackpadSwipeEnabled &&
        isSwipeDismissEnabled &&
        (!isActivityPresentationHidden || isLocked || hasTemporaryNotification) &&
        hasRealDisplayedContent
    }

    func canRestoreWithTrackpadSwipe(
        isTrackpadSwipeEnabled: Bool,
        isSwipeRestoreEnabled: Bool,
        isLocked: Bool,
        isLiveActivityExpanded: Bool,
        canRestoreDismissedContent: Bool
    ) -> Bool {
        guard !isLocked else { return false }
        guard !isLiveActivityExpanded else { return false }
        return isTrackpadSwipeEnabled &&
        isSwipeRestoreEnabled &&
        canRestoreDismissedContent
    }

    func canDismissWithHorizontalTrackpadSwipe(
        canDismissWithTrackpadSwipe: Bool,
        isDisplayingExpandedLiveActivity: Bool,
        notchHeight: CGFloat,
        baseHeight: CGFloat
    ) -> Bool {
        guard canDismissWithTrackpadSwipe else { return false }
        return isDisplayingExpandedLiveActivity || notchHeight > baseHeight + 1
    }

    func canDismissWithHorizontalMouseDrag(
        canDismissWithMouseDrag: Bool
    ) -> Bool {
        canDismissWithMouseDrag
    }

    // MARK: - Swipe Stretch State Updates

    func updateSwipeStretch(for interaction: SwipeInteraction, progress: CGFloat) {
        swipeStretchResetWorkItem?.cancel()
        swipeStretchResetWorkItem = nil

        let clampedProgress = max(progress, 0)
        guard swipeInteraction != interaction || abs(swipeStretchProgress - clampedProgress) > 0.001 else {
            return
        }

        swipeInteraction = interaction
        swipeStretchProgress = clampedProgress

        switch interaction {
        case .simultaneousDismiss(let vertical, let horizontal):
            verticalSwipeStretchProgress = max(0, vertical)
            horizontalSwipeStretchProgress = max(0, horizontal)
        case .dismiss:
            verticalSwipeStretchProgress = clampedProgress
            horizontalSwipeStretchProgress = 0
        case .horizontalDismiss:
            verticalSwipeStretchProgress = 0
            horizontalSwipeStretchProgress = clampedProgress
        case .restore:
            verticalSwipeStretchProgress = clampedProgress
            horizontalSwipeStretchProgress = 0
        }
    }

    func resetSwipeStretch(animation: Animation?) {
        guard swipeStretchProgress > 0 || verticalSwipeStretchProgress > 0 || horizontalSwipeStretchProgress > 0 || swipeInteraction != nil else {
            return
        }

        swipeStretchResetWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.applySwipeStretchReset(animation: animation)
        }
        swipeStretchResetWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }

    func applySwipeStretchReset(animation: Animation?) {
        swipeStretchResetWorkItem = nil
        guard swipeStretchProgress > 0 || verticalSwipeStretchProgress > 0 || horizontalSwipeStretchProgress > 0 || swipeInteraction != nil else {
            return
        }

        withAnimation(animation) {
            swipeStretchProgress = 0
            verticalSwipeStretchProgress = 0
            horizontalSwipeStretchProgress = 0
            swipeInteraction = nil
        }
    }

    // MARK: - Interactive Geometry & Feedback Calculation

    func interactiveNotchSize(
        model: NotchModel,
        focusCloseStretchWidth: CGFloat = 0,
        focusCloseStretchHeight: CGFloat = 0,
        notchPulseWidth: CGFloat = 0,
        notchPulseHeight: CGFloat = 0
    ) -> CGSize {
        let baseSize = model.size
        let progress = easedSwipeStretchProgress
        let calculatedSize: CGSize

        switch swipeInteraction {
        case .dismiss:
            if model.isPresentingExpandedLiveActivity || baseSize.height > model.baseHeight + 1 {
                let heightCompression = min(
                    max(baseSize.height * SwipeFeedbackMetrics.expandedDismissHeightFactor, SwipeFeedbackMetrics.expandedDismissMinimumHeight),
                    SwipeFeedbackMetrics.expandedDismissMaximumHeight
                )

                calculatedSize = CGSize(
                    width: baseSize.width,
                    height: max(model.baseHeight, baseSize.height - (heightCompression * progress))
                )
            } else {
                let widthCompression = min(
                    max(baseSize.width * SwipeFeedbackMetrics.collapsedDismissWidthFactor, SwipeFeedbackMetrics.collapsedDismissMinimumWidth),
                    SwipeFeedbackMetrics.collapsedDismissMaximumWidth
                )

                let targetWidth = deceleratedWidthTowardsBase(
                    currentWidth: baseSize.width,
                    baseWidth: model.baseWidth,
                    nominalCompression: widthCompression,
                    progress: progress
                )

                calculatedSize = CGSize(
                    width: targetWidth,
                    height: baseSize.height
                )
            }

        case .horizontalDismiss:
            let widthCompression = min(
                max(baseSize.width * SwipeFeedbackMetrics.collapsedDismissWidthFactor, SwipeFeedbackMetrics.collapsedDismissMinimumWidth),
                SwipeFeedbackMetrics.collapsedDismissMaximumWidth
            )

            let targetWidth = deceleratedWidthTowardsBase(
                currentWidth: baseSize.width,
                baseWidth: model.baseWidth,
                nominalCompression: widthCompression,
                progress: progress
            )

            calculatedSize = CGSize(
                width: targetWidth,
                height: baseSize.height
            )

        case .simultaneousDismiss:
            let easedHProgress = easedProgress(for: horizontalSwipeStretchProgress)
            let easedVProgress = easedProgress(for: verticalSwipeStretchProgress)

            let widthCompression = min(
                max(baseSize.width * SwipeFeedbackMetrics.collapsedDismissWidthFactor, SwipeFeedbackMetrics.collapsedDismissMinimumWidth),
                SwipeFeedbackMetrics.collapsedDismissMaximumWidth
            )

            if model.isPresentingExpandedLiveActivity || baseSize.height > model.baseHeight + 1 {
                let targetWidth = deceleratedWidthTowardsBase(
                    currentWidth: baseSize.width,
                    baseWidth: model.baseWidth,
                    nominalCompression: widthCompression,
                    progress: easedHProgress
                )

                let heightCompression = min(
                    max(baseSize.height * SwipeFeedbackMetrics.expandedDismissHeightFactor, SwipeFeedbackMetrics.expandedDismissMinimumHeight),
                    SwipeFeedbackMetrics.expandedDismissMaximumHeight
                )

                let targetHeight = max(model.baseHeight, baseSize.height - (heightCompression * easedVProgress))

                calculatedSize = CGSize(
                    width: targetWidth,
                    height: targetHeight
                )
            } else {
                let combinedProgress = max(easedHProgress, easedVProgress)
                let targetWidth = deceleratedWidthTowardsBase(
                    currentWidth: baseSize.width,
                    baseWidth: model.baseWidth,
                    nominalCompression: widthCompression,
                    progress: combinedProgress
                )

                calculatedSize = CGSize(
                    width: targetWidth,
                    height: baseSize.height
                )
            }

        case .restore:
            calculatedSize = CGSize(
                width: baseSize.width,
                height: baseSize.height + (SwipeFeedbackMetrics.restoreHeightExpansion * progress)
            )

        case nil:
            calculatedSize = baseSize
        }

        return CGSize(
            width: calculatedSize.width + focusCloseStretchWidth + notchPulseWidth,
            height: calculatedSize.height + focusCloseStretchHeight + notchPulseHeight
        )
    }

    func dynamicIslandCornerRadiusExpansion(
        isDynamicIsland: Bool,
        modelHeight: CGFloat,
        baseHeight: CGFloat
    ) -> CGFloat {
        if isDynamicIsland && swipeInteraction != nil && modelHeight > baseHeight {
            return SwipeFeedbackMetrics.swipeCornerRadiusExpansion * easedSwipeStretchProgress
        }
        return 0
    }

    func contentResizeBlurRadius() -> CGFloat {
        let progress = min(1.0, easedSwipeStretchProgress)

        switch swipeInteraction {
        case .dismiss, .horizontalDismiss, .simultaneousDismiss:
            return SwipeFeedbackMetrics.dismissBlurRadius * progress
        case .restore:
            return SwipeFeedbackMetrics.restoreBlurRadius * progress
        case nil:
            return 0
        }
    }

    func contentResizeOpacity() -> Double {
        let progress = Double(easedSwipeStretchProgress)

        switch swipeInteraction {
        case .dismiss, .horizontalDismiss, .simultaneousDismiss:
            return max(0, 1 - (SwipeFeedbackMetrics.dismissOpacityReduction * progress))
        case .restore:
            return max(0, 1 - (SwipeFeedbackMetrics.restoreOpacityReduction * progress))
        case nil:
            return 1
        }
    }

    private func deceleratedWidthTowardsBase(
        currentWidth: CGFloat,
        baseWidth: CGFloat,
        nominalCompression: CGFloat,
        progress: CGFloat
    ) -> CGFloat {
        let distanceToBase = currentWidth - baseWidth
        guard distanceToBase > 0, progress > 0 else {
            return currentWidth
        }

        let effectiveCompression = min(nominalCompression, distanceToBase)
        let actualCompression = effectiveCompression * progress
        return max(baseWidth, currentWidth - actualCompression)
    }
}
