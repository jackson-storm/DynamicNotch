//
//  NotchContentProvider.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/25/26.
//

import SwiftUI

protocol NotchContentProtocol: DynamicIslandCustomizable {
    var id: String { get }
    var stackID: String { get }
    var priority: Int { get }
    var strokeColor: Color { get }
    var isExpandable: Bool { get }
    var expandsOnTap: Bool { get }
    var isRestorable: Bool { get }
    var usesContentResizeEffect: Bool { get }
    var windowLink: (@MainActor () -> Void)? { get }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat)
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat)
    
    @MainActor @ViewBuilder func makeView() -> AnyView
    @MainActor @ViewBuilder func makeExpandedView() -> AnyView
}

extension NotchContentProtocol {
    var stackID: String { id }
    var priority: Int { NotchContentPriority.default }
    var strokeColor: Color { .white.opacity(0.2) }
    var isExpandable: Bool { false }
    var expandsOnTap: Bool { isExpandable }
    var isRestorable: Bool { true }
    var usesContentResizeEffect: Bool { true }
    var windowLink: (@MainActor () -> Void)? { nil }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: baseRadius - 4, bottom: baseRadius)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        size(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        cornerRadius(baseRadius: baseRadius)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        size(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let base = expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
        return CGSize(width: base.width + 40, height: base.height)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        makeView()
    }
}
