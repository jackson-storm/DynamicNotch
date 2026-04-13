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
    private let interactiveBlur: CGFloat
    private let interactiveOpacity: Double

    private enum Metrics {
        static let maxBlurRadius: CGFloat = 5
        static let maxNormalizedDelta: CGFloat = 0.18
        static let maxOpacityReduction: Double = 0.28
    }

    init(size: CGSize, interactiveBlur: CGFloat, interactiveOpacity: Double) {
        animatedWidth = size.width
        animatedHeight = size.height
        targetWidth = size.width
        targetHeight = size.height
        self.interactiveBlur = interactiveBlur
        self.interactiveOpacity = interactiveOpacity
    }

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            .init(animatedWidth, animatedHeight)
        }
        set {
            animatedWidth = newValue.first
            animatedHeight = newValue.second
        }
    }

    func body(content: Content) -> some View {
        let widthDelta = normalizedDelta(abs(targetWidth - animatedWidth), relativeTo: targetWidth)
        let heightDelta = normalizedDelta(abs(targetHeight - animatedHeight), relativeTo: targetHeight)
        let normalizedProgress = max(widthDelta, heightDelta)
        let transitionBlur = normalizedProgress * Metrics.maxBlurRadius
        let blurRadius = max(transitionBlur, interactiveBlur)
        let transitionOpacity = max(0, 1 - (Double(normalizedProgress) * Metrics.maxOpacityReduction))
        let opacity = min(transitionOpacity, interactiveOpacity)

        return content
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
    func resizeAwareBlur(size: CGSize, interactiveBlur: CGFloat, interactiveOpacity: Double) -> some View {
        modifier(
            ResizeAwareBlurModifier(
                size: size,
                interactiveBlur: interactiveBlur,
                interactiveOpacity: interactiveOpacity
            )
        )
    }
}
