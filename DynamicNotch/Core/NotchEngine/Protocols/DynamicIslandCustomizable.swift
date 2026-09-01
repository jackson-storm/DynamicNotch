//
//  DynamicIslandCustomizable.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/30/26.
//

import Foundation

protocol DynamicIslandCustomizable {
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize
    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat
    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat
}

extension DynamicIslandCustomizable where Self: NotchContentProtocol {
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        size(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }
}
