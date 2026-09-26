//
//  extension+AnyTransition.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/27/26.
//

import SwiftUI

extension AnyTransition {
    static var blurAndFade: AnyTransition {
        .modifier(
            active: BlurFadeModifier(blur: 15, opacity: 0),
            identity: BlurFadeModifier(blur: 0, opacity: 1)
        )
    }

    static func notchContent(
        notchWidth: CGFloat = 0,
        notchHeight: CGFloat,
        baseWidth: CGFloat = 0,
        baseHeight: CGFloat,
        isExpandedPresentation: Bool,
        isNotchlessScreen: Bool = false
    ) -> AnyTransition {
        if isExpandedPresentation {
            return notchExpanded(
                notchHeight: notchHeight,
                baseHeight: baseHeight,
                isNotchlessScreen: isNotchlessScreen
            )
        }
        return notchCompact(
            notchWidth: notchWidth,
            notchHeight: notchHeight,
            baseWidth: baseWidth,
            baseHeight: baseHeight,
            isNotchlessScreen: isNotchlessScreen
        )
    }

    static func notchCompact(
        notchWidth: CGFloat = 0,
        notchHeight: CGFloat,
        baseWidth: CGFloat = 0,
        baseHeight: CGFloat,
        isNotchlessScreen: Bool = false
    ) -> AnyTransition {
        let verticalOffset = NotchTransitionMetrics.verticalCompensationOffset(
            for: notchHeight,
            baseHeight: baseHeight,
            isNotchlessScreen: isNotchlessScreen
        )
        let scaleX = NotchTransitionMetrics.compactScaleX(for: notchWidth, baseWidth: baseWidth)
        let scaleY = NotchTransitionMetrics.compactScaleY(for: notchHeight, baseHeight: baseHeight)
        
        return .asymmetric(
            insertion: .modifier(
                active: NotchTransitionModifier(
                    blur: 15,
                    opacity: 0,
                    offsetY: verticalOffset,
                    scaleX: scaleX,
                    scaleY: scaleY,
                    anchor: .center
                ),
                identity: NotchTransitionModifier(anchor: .center)
            ),
            removal: .modifier(
                active: NotchTransitionModifier(
                    blur: 15,
                    opacity: 0,
                    offsetY: verticalOffset,
                    scaleX: scaleX,
                    scaleY: scaleY,
                    anchor: .center
                ),
                identity: NotchTransitionModifier(anchor: .center)
            )
        )
    }

    static func notchExpanded(
        notchHeight: CGFloat,
        baseHeight: CGFloat,
        isNotchlessScreen: Bool = false
    ) -> AnyTransition {
        let verticalOffset = NotchTransitionMetrics.verticalCompensationOffset(
            for: notchHeight,
            baseHeight: baseHeight,
            isNotchlessScreen: isNotchlessScreen
        )
        
        return .asymmetric(
            insertion: .modifier(
                active: NotchTransitionModifier(
                    blur: 30,
                    opacity: 0,
                    offsetY: verticalOffset,
                    scaleX: 0.6,
                    scaleY: 0.2,
                    anchor: .center
                ),
                identity: NotchTransitionModifier(anchor: .center)
            ),
            removal: .modifier(
                active: NotchTransitionModifier(
                    blur: 30,
                    opacity: 0,
                    offsetY: verticalOffset,
                    scaleX: 0.4,
                    scaleY: 0.2,
                    anchor: .center
                ),
                identity: NotchTransitionModifier(anchor: .center)
            )
        )
    }
}
