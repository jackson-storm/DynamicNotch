//
//  ResizeAwareBlurModifier.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/13/26.
//

import SwiftUI

struct ResizeAwareBlurModifier: AnimatableModifier {
    private var animatedWidth: CGFloat
    private var animatedHeight: CGFloat
    private let targetWidth: CGFloat
    private let targetHeight: CGFloat
    private let baseHeight: CGFloat
    private let isResizeEffectEnabled: Bool
    private let interactiveBlur: CGFloat
    private let interactiveOpacity: Double
    private var animatedProgress: CGFloat
    private let swipeInteraction: SwipeInteraction?

    private enum Metrics {
        static let maxBlurRadius: CGFloat = 20
        static let maxNormalizedDelta: CGFloat = 0.1
        static let maxOpacityReduction: Double = 0.9
    }

    init(size: CGSize, baseHeight: CGFloat = 38, isResizeEffectEnabled: Bool = true, interactiveBlur: CGFloat, interactiveOpacity: Double, swipeProgress: CGFloat, swipeInteraction: SwipeInteraction?) {
        animatedWidth = size.width
        animatedHeight = size.height
        targetWidth = size.width
        targetHeight = size.height
        self.baseHeight = baseHeight
        self.isResizeEffectEnabled = isResizeEffectEnabled
        self.interactiveBlur = interactiveBlur
        self.interactiveOpacity = interactiveOpacity
        self.animatedProgress = swipeProgress
        self.swipeInteraction = swipeInteraction
    }

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get {
            .init(.init(animatedWidth, animatedHeight), animatedProgress)
        }
        set {
            animatedWidth = newValue.first.first
            animatedHeight = newValue.first.second
            animatedProgress = newValue.second
        }
    }

    func body(content: Content) -> some View {
        let widthDelta = normalizedDelta(abs(targetWidth - animatedWidth), relativeTo: targetWidth)
        let heightDelta = normalizedDelta(abs(targetHeight - animatedHeight), relativeTo: targetHeight)
        let normalizedProgress = isResizeEffectEnabled ? max(widthDelta, heightDelta) : 0
        let transitionBlur = normalizedProgress * Metrics.maxBlurRadius
        let blurRadius = max(transitionBlur, interactiveBlur)
        let transitionOpacity = max(0, 1 - (Double(normalizedProgress) * Metrics.maxOpacityReduction))
        let opacity = min(transitionOpacity, interactiveOpacity)

        let isBaseHeight = targetHeight <= baseHeight + 1
        let xScale: CGFloat
        let yScale: CGFloat

        if animatedProgress > 0.001, let interaction = swipeInteraction {
            switch interaction {
            case .dismiss:
                if isBaseHeight {
                    yScale = 1.0 + animatedProgress * 0.05
                    xScale = 1.0
                } else {
                    yScale = max(0.8, 1.0 - animatedProgress * 0.1)
                    xScale = 1.0
                }
            case .restore:
                if isBaseHeight {
                    yScale = 1.0 + animatedProgress * 0.5
                    xScale = 1.0
                } else {
                    yScale = 1.0 + animatedProgress * 0.02
                    xScale = 1.0
                }
            }
        } else if isResizeEffectEnabled {
            xScale = targetWidth > 0 ? (animatedWidth / targetWidth) : 1.0
            yScale = targetHeight > 0 ? (animatedHeight / targetHeight) : 1.0
        } else {
            xScale = 1
            yScale = 1
        }

        return content
            .scaleEffect(x: xScale, y: yScale, anchor: .center)
            .blur(radius: blurRadius)
            .opacity(opacity)
            .compositingGroup()
    }

    private func normalizedDelta(_ delta: CGFloat, relativeTo target: CGFloat) -> CGFloat {
        guard target > 0 else { return 0 }
        return min((delta / target) / Metrics.maxNormalizedDelta, 1)
    }
}

extension View {
    func resizeAwareBlur(
        size: CGSize,
        baseHeight: CGFloat = 38,
        isResizeEffectEnabled: Bool = true,
        interactiveBlur: CGFloat,
        interactiveOpacity: Double,
        swipeProgress: CGFloat,
        swipeInteraction: SwipeInteraction?) -> some View {
        modifier(
            ResizeAwareBlurModifier(
                size: size,
                baseHeight: baseHeight,
                isResizeEffectEnabled: isResizeEffectEnabled,
                interactiveBlur: interactiveBlur,
                interactiveOpacity: interactiveOpacity,
                swipeProgress: swipeProgress,
                swipeInteraction: swipeInteraction
            )
        )
    }
}
