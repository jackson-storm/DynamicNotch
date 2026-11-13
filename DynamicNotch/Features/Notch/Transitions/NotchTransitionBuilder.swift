//
//  NotchTransitionBuilder.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 11/10/26.
//

import SwiftUI

enum NotchTransitionBuilder {
    static func build(
        notchWidth: CGFloat,
        notchHeight: CGFloat,
        baseWidth: CGFloat,
        baseHeight: CGFloat,
        isDynamicIsland: Bool,
        isExpandedPresentation: Bool,
        animations: NotchAnimations
    ) -> AnyTransition {
        let expandedTransition = AnyTransition.notchExpanded(
            notchHeight: notchHeight,
            baseHeight: baseHeight,
            isNotchlessScreen: isDynamicIsland
        )
        let compactTransition = AnyTransition.notchCompact(
            notchWidth: notchWidth,
            notchHeight: notchHeight,
            baseWidth: baseWidth,
            baseHeight: baseHeight,
            isNotchlessScreen: isDynamicIsland
        )

        if isExpandedPresentation {
            return .asymmetric(
                insertion: expandedTransition.animation(animations.expandLiveActivity),
                removal: expandedTransition.animation(animations.collapseLiveActivity)
            )
        } else {
            return .asymmetric(
                insertion: compactTransition.animation(animations.showContent),
                removal: compactTransition.animation(animations.hideContent)
            )
        }
    }
}
