//
//  NotchTransitionMetrics.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/27/26.
//

import SwiftUI

enum NotchTransitionMetrics {
    static let horizontalCompensationRatio: CGFloat = 3.0 / 13.0

    static func horizontalCompensationOffset(for notchWidth: CGFloat) -> CGFloat {
        -(max(0, notchWidth) * horizontalCompensationRatio)
    }

    static func verticalCompensationOffset(for notchHeight: CGFloat, baseHeight: CGFloat) -> CGFloat {
        -(max(0, notchHeight - baseHeight) / 2)
    }
}
