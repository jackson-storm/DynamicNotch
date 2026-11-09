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
    var offsetY: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: max(0.001, scaleX), y: max(0.001, scaleY), anchor: anchor)
            .offset(y: offsetY)
            .blur(radius: max(0, blur))
            .opacity(max(0, min(1, opacity)))
    }
}
