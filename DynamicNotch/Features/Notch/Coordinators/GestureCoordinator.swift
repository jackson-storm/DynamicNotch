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

    struct Context {
        let settings: NotchSettingsProviding
        let isLocked: Bool
        let isActivityPresentationHidden: Bool
        let hasTemporaryNotification: Bool
        let hasRealDisplayedContent: Bool
        let isExpandedPresentation: Bool
        let canRestoreDismissedContent: Bool
    }

    func canDismissWithMouseDrag(context: Context) -> Bool {
        canDismissWithMouseDrag(
            isMouseDragEnabled: context.settings.isNotchMouseDragGesturesEnabled,
            isSwipeDismissEnabled: context.settings.isNotchSwipeDismissEnabled,
            isLocked: context.isLocked,
            isActivityPresentationHidden: context.isActivityPresentationHidden,
            hasTemporaryNotification: context.hasTemporaryNotification,
            hasRealDisplayedContent: context.hasRealDisplayedContent
        )
    }

    func canRestoreWithMouseDrag(context: Context) -> Bool {
        canRestoreWithMouseDrag(
            isMouseDragEnabled: context.settings.isNotchMouseDragGesturesEnabled,
            isSwipeRestoreEnabled: context.settings.isNotchSwipeRestoreEnabled,
            isLocked: context.isLocked,
            isLiveActivityExpanded: context.isExpandedPresentation,
            canRestoreDismissedContent: context.canRestoreDismissedContent,
            hasRealDisplayedContent: context.hasRealDisplayedContent
        )
    }

    func canDismissWithTrackpadSwipe(context: Context) -> Bool {
        canDismissWithTrackpadSwipe(
            isTrackpadSwipeEnabled: context.settings.isNotchTrackpadSwipeGesturesEnabled,
            isSwipeDismissEnabled: context.settings.isNotchSwipeDismissEnabled,
            isLocked: context.isLocked,
            isActivityPresentationHidden: context.isActivityPresentationHidden,
            hasTemporaryNotification: context.hasTemporaryNotification,
            hasRealDisplayedContent: context.hasRealDisplayedContent
        )
    }

    func canRestoreWithTrackpadSwipe(context: Context) -> Bool {
        canRestoreWithTrackpadSwipe(
            isTrackpadSwipeEnabled: context.settings.isNotchTrackpadSwipeGesturesEnabled,
            isSwipeRestoreEnabled: context.settings.isNotchSwipeRestoreEnabled,
            isLocked: context.isLocked,
            isLiveActivityExpanded: context.isExpandedPresentation,
            canRestoreDismissedContent: context.canRestoreDismissedContent,
            hasRealDisplayedContent: context.hasRealDisplayedContent
        )
    }

    func canStretchWithMouseDrag(context: Context) -> Bool {
        canStretchWithMouseDrag(
            isMouseDragEnabled: context.settings.isNotchMouseDragGesturesEnabled,
            isSwipeGesturesEnabled: context.settings.isNotchSwipeDismissEnabled || context.settings.isNotchSwipeRestoreEnabled,
            isLocked: context.isLocked
        )
    }

    func canStretchWithTrackpadSwipe(context: Context) -> Bool {
        canStretchWithTrackpadSwipe(
            isTrackpadSwipeEnabled: context.settings.isNotchTrackpadSwipeGesturesEnabled,
            isSwipeGesturesEnabled: context.settings.isNotchSwipeDismissEnabled || context.settings.isNotchSwipeRestoreEnabled,
            isLocked: context.isLocked
        )
    }

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
        guard !isLiveActivityExpanded else { return false }
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
        guard !isLiveActivityExpanded else { return false }
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
            let nominalWidthExpansion = max(
                baseSize.width * SwipeFeedbackMetrics.horizontalExpandWidthFactor,
                SwipeFeedbackMetrics.horizontalExpandMinimumWidth
            )
            let widthExpansion = deceleratedExpansion(
                nominalExpansion: nominalWidthExpansion,
                progress: progress
            )

            calculatedSize = CGSize(
                width: baseSize.width + widthExpansion,
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
            if model.isPresentingExpandedLiveActivity || baseSize.height > model.baseHeight + 1 {
                let nominalHeightExpansion = max(
                    baseSize.height * SwipeFeedbackMetrics.verticalExpandHeightFactor,
                    SwipeFeedbackMetrics.verticalExpandMinimumHeight
                )
                let heightExpansion = deceleratedExpansion(
                    nominalExpansion: nominalHeightExpansion,
                    progress: progress
                )
                calculatedSize = CGSize(
                    width: baseSize.width,
                    height: baseSize.height + heightExpansion
                )
            } else {
                let nominalWidthExpansion = max(
                    baseSize.width * SwipeFeedbackMetrics.horizontalExpandWidthFactor,
                    SwipeFeedbackMetrics.horizontalExpandMinimumWidth
                )
                let widthExpansion = deceleratedExpansion(
                    nominalExpansion: nominalWidthExpansion,
                    progress: progress
                )

                calculatedSize = CGSize(
                    width: baseSize.width + widthExpansion,
                    height: baseSize.height
                )
            }

        case .combined(let vDir, _, let hDir, _):
            let easedHProgress = easedProgress(for: horizontalSwipeStretchProgress)
            let easedVProgress = easedProgress(for: verticalSwipeStretchProgress)

            if model.isPresentingExpandedLiveActivity || baseSize.height > model.baseHeight + 1 {
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
                    let nominalWidthExpansion = max(
                        baseSize.width * SwipeFeedbackMetrics.horizontalExpandWidthFactor,
                        SwipeFeedbackMetrics.horizontalExpandMinimumWidth
                    )
                    targetWidth = baseSize.width + deceleratedExpansion(
                        nominalExpansion: nominalWidthExpansion,
                        progress: easedHProgress
                    )
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
                    let nominalHeightExpansion = max(
                        baseSize.height * SwipeFeedbackMetrics.verticalExpandHeightFactor,
                        SwipeFeedbackMetrics.verticalExpandMinimumHeight
                    )
                    targetHeight = baseSize.height + deceleratedExpansion(
                        nominalExpansion: nominalHeightExpansion,
                        progress: easedVProgress
                    )
                }

                calculatedSize = CGSize(
                    width: targetWidth,
                    height: targetHeight
                )
            } else {
                let isCompressing: Bool
                let effectiveProgress: CGFloat

                let vIsCompress = (vDir == .up)
                let hIsCompress = (hDir == .inward)

                if vIsCompress == hIsCompress {
                    isCompressing = vIsCompress
                    effectiveProgress = max(easedHProgress, easedVProgress)
                } else {
                    if easedHProgress >= easedVProgress {
                        isCompressing = hIsCompress
                        effectiveProgress = easedHProgress
                    } else {
                        isCompressing = vIsCompress
                        effectiveProgress = easedVProgress
                    }
                }

                let targetWidth: CGFloat
                if isCompressing {
                    let widthCompression = min(
                        max(baseSize.width * SwipeFeedbackMetrics.collapsedDismissWidthFactor, SwipeFeedbackMetrics.collapsedDismissMinimumWidth),
                        SwipeFeedbackMetrics.collapsedDismissMaximumWidth
                    )
                    targetWidth = deceleratedWidthTowardsBase(
                        currentWidth: baseSize.width,
                        baseWidth: model.baseWidth,
                        nominalCompression: widthCompression,
                        progress: effectiveProgress,
                        isDynamicIsland: model.isDynamicIsland
                    )
                } else {
                    let nominalWidthExpansion = max(
                        baseSize.width * SwipeFeedbackMetrics.horizontalExpandWidthFactor,
                        SwipeFeedbackMetrics.horizontalExpandMinimumWidth
                    )
                    targetWidth = baseSize.width + deceleratedExpansion(
                        nominalExpansion: nominalWidthExpansion,
                        progress: effectiveProgress
                    )
                }

                calculatedSize = CGSize(
                    width: targetWidth,
                    height: baseSize.height
                )
            }

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
        modelHeight: CGFloat = 0,
        baseHeight: CGFloat = 0
    ) -> CGFloat {
        if isDynamicIsland && swipeInteraction != nil {
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

    func deceleratedExpansion(
        nominalExpansion: CGFloat,
        progress: CGFloat
    ) -> CGFloat {
        guard progress > 0, nominalExpansion > 0 else { return 0 }
        let p = Double(progress)
        let curve = CGFloat(tanh(p) + 0.35 * log(1.0 + p))
        return nominalExpansion * curve
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
