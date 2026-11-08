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
        canRestoreDismissedContent: Bool,
        hasRealDisplayedContent: Bool = false
    ) -> Bool {
        guard !isLocked else { return false }
        guard isMouseDragEnabled && isSwipeRestoreEnabled else { return false }
        return canRestoreDismissedContent
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
        canRestoreDismissedContent: Bool,
        hasRealDisplayedContent: Bool = false
    ) -> Bool {
        guard !isLocked else { return false }
        guard isTrackpadSwipeEnabled && isSwipeRestoreEnabled else { return false }
        return canRestoreDismissedContent
    }

    func canDismissWithHorizontalTrackpadSwipe(
        canDismissWithTrackpadSwipe: Bool,
        isDisplayingExpandedLiveActivity: Bool,
        notchHeight: CGFloat,
        baseHeight: CGFloat
    ) -> Bool {
        canDismissWithTrackpadSwipe
    }

    func canDismissWithHorizontalMouseDrag(
        canDismissWithMouseDrag: Bool
    ) -> Bool {
        canDismissWithMouseDrag
    }

    func canStretchWithMouseDrag(
        isMouseDragEnabled: Bool,
        isSwipeGesturesEnabled: Bool,
        isLocked: Bool
    ) -> Bool {
        guard !isLocked else { return false }
        return isMouseDragEnabled && isSwipeGesturesEnabled
    }

    func canStretchWithTrackpadSwipe(
        isTrackpadSwipeEnabled: Bool,
        isSwipeGesturesEnabled: Bool,
        isLocked: Bool
    ) -> Bool {
        guard !isLocked else { return false }
        return isTrackpadSwipeEnabled && isSwipeGesturesEnabled
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
        case .combined(_, let vertical, _, let horizontal):
            verticalSwipeStretchProgress = max(0, vertical)
            horizontalSwipeStretchProgress = max(0, horizontal)
        case .dismiss:
            verticalSwipeStretchProgress = clampedProgress
            horizontalSwipeStretchProgress = 0
        case .horizontalDismiss, .horizontalExpand:
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

                let minHeight = model.isDynamicIsland ? model.baseHeight * 0.75 : model.baseHeight - 4
                calculatedSize = CGSize(
                    width: baseSize.width,
                    height: max(minHeight, baseSize.height - (heightCompression * progress))
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
                    progress: progress,
                    isDynamicIsland: model.isDynamicIsland
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
                progress: progress,
                isDynamicIsland: model.isDynamicIsland
            )

            calculatedSize = CGSize(
                width: targetWidth,
                height: baseSize.height
            )

        case .horizontalExpand:
            let widthExpansion = min(
                max(baseSize.width * SwipeFeedbackMetrics.horizontalExpandWidthFactor, SwipeFeedbackMetrics.horizontalExpandMinimumWidth),
                SwipeFeedbackMetrics.horizontalExpandMaximumWidth
            )

            calculatedSize = CGSize(
                width: baseSize.width + (widthExpansion * progress),
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
                    progress: easedHProgress,
                    isDynamicIsland: model.isDynamicIsland
                )

                let heightCompression = min(
                    max(baseSize.height * SwipeFeedbackMetrics.expandedDismissHeightFactor, SwipeFeedbackMetrics.expandedDismissMinimumHeight),
                    SwipeFeedbackMetrics.expandedDismissMaximumHeight
                )

                let minHeight = model.isDynamicIsland ? model.baseHeight * 0.75 : model.baseHeight - 4
                let targetHeight = max(minHeight, baseSize.height - (heightCompression * easedVProgress))

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
                    progress: combinedProgress,
                    isDynamicIsland: model.isDynamicIsland
                )

                calculatedSize = CGSize(
                    width: targetWidth,
                    height: baseSize.height
                )
            }

        case .restore:
            let heightExpansion = min(
                max(baseSize.height * SwipeFeedbackMetrics.verticalExpandHeightFactor, SwipeFeedbackMetrics.verticalExpandMinimumHeight),
                SwipeFeedbackMetrics.verticalExpandMaximumHeight
            )
            calculatedSize = CGSize(
                width: baseSize.width,
                height: baseSize.height + (heightExpansion * progress)
            )

        case .combined(let vDir, _, let hDir, _):
            let easedHProgress = easedProgress(for: horizontalSwipeStretchProgress)
            let easedVProgress = easedProgress(for: verticalSwipeStretchProgress)

            let targetWidth: CGFloat
            if hDir == .inward {
                let widthCompression = min(
                    max(baseSize.width * SwipeFeedbackMetrics.collapsedDismissWidthFactor, SwipeFeedbackMetrics.collapsedDismissMinimumWidth),
                    SwipeFeedbackMetrics.collapsedDismissMaximumWidth
                )
                targetWidth = deceleratedWidthTowardsBase(
                    currentWidth: baseSize.width,
                    baseWidth: model.baseWidth,
                    nominalCompression: widthCompression,
                    progress: easedHProgress,
                    isDynamicIsland: model.isDynamicIsland
                )
            } else {
                let widthExpansion = min(
                    max(baseSize.width * SwipeFeedbackMetrics.horizontalExpandWidthFactor, SwipeFeedbackMetrics.horizontalExpandMinimumWidth),
                    SwipeFeedbackMetrics.horizontalExpandMaximumWidth
                )
                targetWidth = baseSize.width + (widthExpansion * easedHProgress)
            }

            let targetHeight: CGFloat
            if vDir == .up {
                let heightCompression = min(
                    max(baseSize.height * SwipeFeedbackMetrics.expandedDismissHeightFactor, SwipeFeedbackMetrics.expandedDismissMinimumHeight),
                    SwipeFeedbackMetrics.expandedDismissMaximumHeight
                )
                let minHeight = model.isDynamicIsland ? model.baseHeight * 0.75 : model.baseHeight - 4
                targetHeight = max(minHeight, baseSize.height - (heightCompression * easedVProgress))
            } else {
                let heightExpansion = min(
                    max(baseSize.height * SwipeFeedbackMetrics.verticalExpandHeightFactor, SwipeFeedbackMetrics.verticalExpandMinimumHeight),
                    SwipeFeedbackMetrics.verticalExpandMaximumHeight
                )
                targetHeight = baseSize.height + (heightExpansion * easedVProgress)
            }

            calculatedSize = CGSize(
                width: targetWidth,
                height: targetHeight
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
        case .restore, .horizontalExpand, .combined:
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
        case .restore, .horizontalExpand, .combined:
            return max(0, 1 - (SwipeFeedbackMetrics.restoreOpacityReduction * progress))
        case nil:
            return 1
        }
    }

    private func deceleratedWidthTowardsBase(
        currentWidth: CGFloat,
        baseWidth: CGFloat,
        nominalCompression: CGFloat,
        progress: CGFloat,
        isDynamicIsland: Bool = false
    ) -> CGFloat {
        let distanceToBase = currentWidth - baseWidth
        if distanceToBase > 0, progress > 0 {
            let effectiveCompression = min(nominalCompression, distanceToBase)
            let actualCompression = effectiveCompression * progress
            return max(baseWidth, currentWidth - actualCompression)
        } else if progress > 0 {
            if isDynamicIsland {
                let compression = min(nominalCompression, baseWidth * 0.2) * progress
                return max(baseWidth * 0.7, currentWidth - compression)
            } else {
                let compression = min(8.0, nominalCompression * 0.2) * progress
                return max(baseWidth - 8.0, currentWidth - compression)
            }
        } else {
            return currentWidth
        }
    }
}
