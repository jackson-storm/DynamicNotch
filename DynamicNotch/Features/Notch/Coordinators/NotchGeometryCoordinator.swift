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

    var isClosingHeightStaged = false

    var isDynamicIsland: Bool {
        topInset == 0
    }

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
