//
//  NotchContentProvider.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/25/26.
//

import SwiftUI

protocol NotchContentProvider {
    var id: String { get }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat)
    
    var strokeColor: Color { get }
    var offsetYTransition: CGFloat { get }
    
    @MainActor @ViewBuilder func makeView() -> AnyView
}

extension NotchContentProvider {
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: baseRadius - 4, bottom: baseRadius)
    }
    
    var strokeColor: Color { .white.opacity(0.15) }
    var offsetYTransition: CGFloat { 0 }
}
