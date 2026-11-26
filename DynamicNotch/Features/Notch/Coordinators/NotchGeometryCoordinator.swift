//
//  NotchGeometryCoordinator.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 11/10/26.
//

import SwiftUI
import Combine

struct CalculatedNotchGeometry {
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let topInset: CGFloat
    let isDynamicIsland: Bool
}

@MainActor
final class NotchGeometryCoordinator: ObservableObject {
    @Published var stagedNotchHeight: CGFloat
    @Published var topInset: CGFloat = 0
    @Published var collapseHeightBoost: CGFloat = 0
    @Published var collapseScale: CGFloat = 1.0
    
    var isClosingHeightStaged = false
    
    var isDynamicIsland: Bool {
        topInset == 0
    }
    
    private var collapseTransitionResetWorkItem: DispatchWorkItem?
    
    init(initialBaseHeight: CGFloat? = nil) {
        self.stagedNotchHeight = initialBaseHeight ?? NotchModel().baseHeight
    }
    
    func calculateGeometry(
        screenMetrics: NotchScreenMetrics,
        notchWidthSetting: Double,
        notchHeightSetting: Double
    ) -> CalculatedNotchGeometry {
        let topInset = screenMetrics.topInset
        let screenWidth = screenMetrics.width
        let baseScreenWidth: CGFloat = 1440.0
        let scale = max(0.35, screenWidth / baseScreenWidth)
        let widthScale = scale > 1.0 ? 1.0 + (scale - 1.0) * 0.35 : scale
        
        let isDynamicIsland = topInset == 0
        let widthOffset = CGFloat(notchWidthSetting) + 2
        let heightOffset = CGFloat(notchHeightSetting)
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
        
        return CalculatedNotchGeometry(
            width: finalWidth,
            height: finalHeight,
            scale: scale,
            topInset: topInset,
            isDynamicIsland: isDynamicIsland
        )
    }
    
    func handleCollapseTransition(
        wasExpanded: Bool,
        isNowExpanded: Bool,
        hasContentAfterTransition: Bool,
        expandedHeight: CGFloat,
        baseHeight: CGFloat,
        heightBoost: CGFloat? = nil,
        targetScale: CGFloat = 1.2,
        resetAfter delay: TimeInterval,
        animation: Animation?
    ) {
        guard wasExpanded, !isNowExpanded, hasContentAfterTransition else {
            return
        }

        let resolvedBoost = heightBoost ?? calculatedCollapseHeightBoost(
            expandedHeight: expandedHeight,
            baseHeight: baseHeight
        )

        collapseTransitionResetWorkItem?.cancel()

        withAnimation(animation) {
            self.collapseHeightBoost = resolvedBoost
            self.collapseScale = isDynamicIsland ? targetScale : 1.0
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation(animation) {
                self.collapseHeightBoost = 0
                self.collapseScale = 1.0
            }
        }
        collapseTransitionResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func calculatedCollapseHeightBoost(
        expandedHeight: CGFloat,
        baseHeight: CGFloat
    ) -> CGFloat {
        let extraHeight = max(0, expandedHeight - baseHeight)
        guard extraHeight > 0 else { return 0 }

        if isDynamicIsland {
            let boost = pow(extraHeight / 60.0, 1.5)
            return min(max(boost, 0.5), 8.0)
        } else {
            let anchorAtSixty: CGFloat = 2.1 * pow(60.0 / 50.0, 1.15)
            let boost = anchorAtSixty * pow(extraHeight / 60.0, 1.55)
            return min(max(boost, 0.5), 7.5)
        }
    }

    func scheduleStagedHeightUpdate(
        to targetHeight: CGFloat,
        isSwipeInteractionActive: Bool,
        animation: Animation?
    ) {
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
        applyStagedHeight(targetHeight, animation: animation)
    }
    
    func applyStagedHeight(_ targetHeight: CGFloat, animation: Animation?) {
        guard let animation else {
            stagedNotchHeight = targetHeight
            return
        }
        
        withAnimation(animation) {
            stagedNotchHeight = targetHeight
        }
    }
    
    func interactiveCornerRadius(
        baseCornerRadius: (top: CGFloat, bottom: CGFloat),
        focusCloseStretchHeight: CGFloat,
        notchPulseHeight: CGFloat
    ) -> (top: CGFloat, bottom: CGFloat) {
        let radiusOffset = (focusCloseStretchHeight + notchPulseHeight) * 0.3
        return (
            top: baseCornerRadius.top + radiusOffset,
            bottom: baseCornerRadius.bottom + radiusOffset
        )
    }
    
    func dynamicIslandCornerRadius(
        height: CGFloat,
        isDisplayingExpandedLiveActivity: Bool,
        displayedContent: NotchContentProtocol?,
        gestureExpansion: CGFloat
    ) -> CGFloat {
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
        return baseRadius + gestureExpansion
    }
}
