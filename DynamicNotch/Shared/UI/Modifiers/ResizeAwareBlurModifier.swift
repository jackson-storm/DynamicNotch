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
    private let referenceBaseSize: CGSize?
    private let baseHeight: CGFloat
    private let anchor: UnitPoint
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

    init(
        size: CGSize,
        baseSize: CGSize? = nil,
        baseHeight: CGFloat = 38,
        anchor: UnitPoint = .center,
        isResizeEffectEnabled: Bool = true,
        interactiveBlur: CGFloat,
        interactiveOpacity: Double,
        swipeProgress: CGFloat,
        swipeInteraction: SwipeInteraction?
    ) {
        animatedWidth = size.width
        animatedHeight = size.height
        targetWidth = size.width
        targetHeight = size.height
        self.referenceBaseSize = baseSize
        self.baseHeight = baseHeight
        self.anchor = anchor
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

        let xScale: CGFloat
        let yScale: CGFloat
        let effectiveAnchor: UnitPoint

        let isExceedingBaseHeight: Bool = {
            if let baseSize = referenceBaseSize {
                return baseSize.height > baseHeight + 1
            }
            return targetHeight > baseHeight + 1
        }()

        if animatedProgress > 0.001, let _ = swipeInteraction, isExceedingBaseHeight, let baseSize = referenceBaseSize, baseSize.width > 0, baseSize.height > 0 {
            xScale = targetWidth / baseSize.width
            yScale = targetHeight / baseSize.height
            effectiveAnchor = anchor
            
        } else if animatedProgress > 0.001, let interaction = swipeInteraction {
            effectiveAnchor = .center
            let isBaseHeight = targetHeight <= baseHeight + 1
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
            effectiveAnchor = anchor
            
        } else {
            xScale = 1
            yScale = 1
            effectiveAnchor = anchor
        }

        return content
            .scaleEffect(x: xScale, y: yScale, anchor: effectiveAnchor)
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
        baseSize: CGSize? = nil,
        baseHeight: CGFloat = 38,
        anchor: UnitPoint = .center,
        isResizeEffectEnabled: Bool = true,
        interactiveBlur: CGFloat,
        interactiveOpacity: Double,
        swipeProgress: CGFloat,
        swipeInteraction: SwipeInteraction?) -> some View {
        modifier(
            ResizeAwareBlurModifier(
                size: size,
                baseSize: baseSize,
                baseHeight: baseHeight,
                anchor: anchor,
                isResizeEffectEnabled: isResizeEffectEnabled,
                interactiveBlur: interactiveBlur,
                interactiveOpacity: interactiveOpacity,
                swipeProgress: swipeProgress,
                swipeInteraction: swipeInteraction
            )
        )
    }
}
