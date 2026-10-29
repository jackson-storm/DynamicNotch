//
//  NotchTransitionMetrics.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/27/26.
//

import SwiftUI

enum NotchTransitionMetrics {
    static func verticalCompensationOffset(for notchHeight: CGFloat, baseHeight: CGFloat, isNotchlessScreen: Bool = false) -> CGFloat {
        let multiplier: CGFloat = isNotchlessScreen ? 0.65 : 0.75
        return -(max(0, notchHeight - baseHeight) * multiplier)
    }

    static func compactScaleX(for notchWidth: CGFloat, baseWidth: CGFloat = 0) -> CGFloat {
        guard notchWidth > 0 else { return 1.0 }
        
        if notchWidth > baseWidth && baseWidth > 0 {
            let scale = baseWidth / notchWidth
            return min(1.0, max(0.1, scale))
        }
        
        return 1.0
    }

    static func compactScaleY(for notchHeight: CGFloat, baseHeight: CGFloat, compactScaleX: CGFloat? = nil) -> CGFloat {
        if let compactScaleX, compactScaleX < 1.0 {
            return compactScaleX
        }
        guard notchHeight > baseHeight else {
            return 1.0
        }
        let extraHeight = notchHeight - baseHeight
        let progress = min(1.0, extraHeight / 140.0)
        return 1.0 - (progress * 0.6)
    }
}

