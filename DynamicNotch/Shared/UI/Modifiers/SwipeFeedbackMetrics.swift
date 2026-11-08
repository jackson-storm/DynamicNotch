//
//  NotchSwipe.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/24/26.
//

import SwiftUI

enum VerticalSwipeDirection: Equatable {
    case up
    case down
}

enum HorizontalSwipeDirection: Equatable {
    case inward
    case outward
}

enum SwipeInteraction: Equatable {
    case dismiss
    case restore
    case horizontalDismiss
    case horizontalExpand
    case simultaneousDismiss(verticalProgress: CGFloat, horizontalProgress: CGFloat)
    case combined(
        verticalDirection: VerticalSwipeDirection,
        verticalProgress: CGFloat,
        horizontalDirection: HorizontalSwipeDirection,
        horizontalProgress: CGFloat
    )
}

enum SwipeFeedbackMetrics {
    static let restoreHeightExpansion: CGFloat = 8
    
    static let verticalExpandHeightFactor: CGFloat = 0.08
    static let verticalExpandMinimumHeight: CGFloat = 6
    static let verticalExpandMaximumHeight: CGFloat = 14
    
    static let collapsedDismissWidthFactor: CGFloat = 0.18
    static let collapsedDismissMinimumWidth: CGFloat = 28
    static let collapsedDismissMaximumWidth: CGFloat = 44

    static let horizontalExpandWidthFactor: CGFloat = 0.09
    static let horizontalExpandMinimumWidth: CGFloat = 14
    static let horizontalExpandMaximumWidth: CGFloat = 22
    
    static let expandedDismissHeightFactor: CGFloat = 0.16
    static let expandedDismissMinimumHeight: CGFloat = 12
    static let expandedDismissMaximumHeight: CGFloat = 28
    
    static let dismissBlurRadius: CGFloat = 8
    static let restoreBlurRadius: CGFloat = 8
    
    static let dismissOpacityReduction: Double = 0.2
    static let restoreOpacityReduction: Double = 0.2
    
    static let swipeCornerRadiusExpansion: CGFloat = 3
}
