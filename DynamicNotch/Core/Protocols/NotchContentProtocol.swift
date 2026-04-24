//
//  NotchContentProvider.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/25/26.
//

import SwiftUI

protocol NotchContentProtocol {
    var id: String { get }
    var stackID: String { get }
    var priority: Int { get }
    var strokeColor: Color { get }
    var isExpandable: Bool { get }
    var expandsOnTap: Bool { get }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat)
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat)
    
    @MainActor @ViewBuilder func makeView() -> AnyView
    @MainActor @ViewBuilder func makeExpandedView() -> AnyView
}

extension NotchContentProtocol {
    var stackID: String { id }
    var priority: Int { 0 }
    var strokeColor: Color { .white.opacity(0.2) }
    var isExpandable: Bool { false }
    var expandsOnTap: Bool { isExpandable }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: baseRadius - 4, bottom: baseRadius)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        size(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        cornerRadius(baseRadius: baseRadius)
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        makeView()
    }
}
