//
//  NotchTransitionMetrics.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/27/26.
//

import SwiftUI

enum NotchTransitionMetrics {
    static func verticalCompensationOffset(for notchHeight: CGFloat, baseHeight: CGFloat) -> CGFloat {
        -(max(0, notchHeight - baseHeight) * 0.75)
    }

    static func compactScaleX(for notchWidth: CGFloat, baseWidth: CGFloat) -> CGFloat {
        let extraWidth = notchWidth - baseWidth
        guard extraWidth > 70 else {
            return 0.8
        }
        let progress = (extraWidth - 70.0) / 70.0
        let scale = 0.8 - (progress * 0.3)
        return min(0.8, max(0.2, scale))
    }

    static func compactScaleY(for notchHeight: CGFloat, baseHeight: CGFloat) -> CGFloat {
        guard notchHeight > baseHeight else {
            return 1.0
        }
        let extraHeight = notchHeight - baseHeight
        let progress = min(1.0, extraHeight / 140.0)
        return 1.0 - (progress * 0.6)
    }
}

