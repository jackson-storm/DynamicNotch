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
            active: BlurFadeModifier(blur: 20, opacity: 0),
            identity: BlurFadeModifier(blur: 0, opacity: 1)
        )
    }

    static func notchContent(notchHeight: CGFloat, baseHeight: CGFloat, isExpandedPresentation: Bool) -> AnyTransition {
        if isExpandedPresentation {
            return notchExpanded(
                notchHeight: notchHeight,
                baseHeight: baseHeight
            )
        }
        return notchCompact(
            notchHeight: notchHeight,
            baseHeight: baseHeight,
        )
    }

    private static func notchCompact(notchHeight: CGFloat, baseHeight: CGFloat) -> AnyTransition {
        let verticalOffset = NotchTransitionMetrics.verticalCompensationOffset(for: notchHeight, baseHeight: baseHeight)
        return .asymmetric(
            insertion: .modifier(
                active: NotchTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetY: verticalOffset,
                    scaleX: 0.4,
                    scaleY: 0.2,
                    anchor: .center
                ),
                identity: NotchTransitionModifier(anchor: .center)
            ),
            removal: .modifier(
                active: NotchTransitionModifier(
                    blur: 20,
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

    private static func notchExpanded(notchHeight: CGFloat, baseHeight: CGFloat) -> AnyTransition {
        let verticalOffset = NotchTransitionMetrics.verticalCompensationOffset(for: notchHeight, baseHeight: baseHeight)
        return .asymmetric(
            insertion: .modifier(
                active: NotchTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetY: verticalOffset / 3,
                    scaleX: 0.4,
                    scaleY: 0.2,
                    anchor: .top
                ),
                identity: NotchTransitionModifier(anchor: .top)
            ),
            removal: .modifier(
                active: NotchTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetY: verticalOffset / 3,
                    scaleX: 0.4,
                    scaleY: 0.2,
                    anchor: .top
                ),
                identity: NotchTransitionModifier(anchor: .top)
            )
        )
    }
}
