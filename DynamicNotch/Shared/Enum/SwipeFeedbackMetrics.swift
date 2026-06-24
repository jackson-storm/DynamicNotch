//
//  NotchSwipe.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/24/26.
//

import SwiftUI

enum SwipeInteraction {
    case dismiss
    case restore
}

enum SwipeFeedbackMetrics {
    static let restoreHeightExpansion: CGFloat = 10
    static let collapsedDismissWidthFactor: CGFloat = 0.18
    static let collapsedDismissMinimumWidth: CGFloat = 28
    static let collapsedDismissMaximumWidth: CGFloat = 44
    static let expandedDismissHeightFactor: CGFloat = 0.16
    static let expandedDismissMinimumHeight: CGFloat = 12
    static let expandedDismissMaximumHeight: CGFloat = 28
    static let restoreCornerRadiusExpansion: CGFloat = 4
    static let restoreTopCornerRadiusExpansion: CGFloat = 12
    static let expandedDismissCornerRadiusReduction: CGFloat = 4
    static let dismissBlurRadius: CGFloat = 7
    static let restoreBlurRadius: CGFloat = 7
    static let dismissOpacityReduction: Double = 0.4
    static let restoreOpacityReduction: Double = 0.4
}
