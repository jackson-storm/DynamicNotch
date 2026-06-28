//
//  NotchTransitionModifier.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/27/26.
//

import SwiftUI

struct NotchTransitionModifier: ViewModifier {
    var blur: CGFloat = 0
    var opacity: Double = 1
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: scaleX, y: scaleY, anchor: anchor)
            .offset(x: offsetX, y: offsetY)
            .blur(radius: blur)
            .opacity(opacity)
            .compositingGroup()
    }
}
