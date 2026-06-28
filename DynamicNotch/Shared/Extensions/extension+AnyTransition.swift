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
            active: BlurFadeModifier(blur: 10, opacity: 0),
            identity: BlurFadeModifier(blur: 0, opacity: 1)
        )
    }

    static func notchContent(
        notchWidth: CGFloat,
        notchHeight: CGFloat,
        baseHeight: CGFloat,
        isExpandedPresentation: Bool,
        isCompactRemovalForExpansion: Bool = false) -> AnyTransition {
            
        if isExpandedPresentation {
            return notchExpanded(
                notchWidth: notchWidth,
                notchHeight: notchHeight,
                baseHeight: baseHeight
            )
        }
        return notchCompact(
            notchWidth: notchWidth,
            notchHeight: notchHeight,
            baseHeight: baseHeight,
            isRemovalForExpansion: isCompactRemovalForExpansion
        )
    }

    private static func notchCompact(notchWidth: CGFloat, notchHeight: CGFloat, baseHeight: CGFloat, isRemovalForExpansion: Bool = false) -> AnyTransition {
        let horizontalOffset = NotchTransitionMetrics.horizontalCompensationOffset(for: notchWidth)
        let removalHorizontalOffset = isRemovalForExpansion ? 0 : horizontalOffset
        let verticalOffset = NotchTransitionMetrics.verticalCompensationOffset(for: notchHeight, baseHeight: baseHeight)

        return .asymmetric(
            insertion: .modifier(
                active: NotchTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetX: horizontalOffset,
                    offsetY: verticalOffset,
                    scaleX: 0.2,
                    scaleY: 0.2,
                    anchor: .center
                ),
                identity: NotchTransitionModifier(anchor: .center)
            ),
            removal: .modifier(
                active: NotchTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetX: removalHorizontalOffset,
                    offsetY: verticalOffset,
                    scaleX: 0.2,
                    scaleY: 0.2,
                    anchor: .center
                ),
                identity: NotchTransitionModifier(anchor: .center)
            )
        )
    }

    private static func notchExpanded(notchWidth: CGFloat, notchHeight: CGFloat, baseHeight: CGFloat) -> AnyTransition {
        let horizontalOffset = NotchTransitionMetrics.horizontalCompensationOffset(for: notchWidth)
        let verticalOffset = NotchTransitionMetrics.verticalCompensationOffset(for: notchHeight, baseHeight: baseHeight)

        return .asymmetric(
            insertion: .modifier(
                active: NotchTransitionModifier(
                    blur: 20,
                    opacity: 0,
                    offsetX: horizontalOffset,
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
                    offsetX: horizontalOffset,
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
