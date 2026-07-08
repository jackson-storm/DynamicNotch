//
//  NotchTransitionMetrics.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/27/26.
//

import SwiftUI

enum NotchTransitionMetrics {
    static func verticalCompensationOffset(for notchHeight: CGFloat, baseHeight: CGFloat) -> CGFloat {
        -(max(0, notchHeight - baseHeight) / 2)
    }
}
