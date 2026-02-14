//
//  NotchPressModifier.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

import SwiftUI

struct NotchPressModifier: ViewModifier {
    @Binding var isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 1.04 : 1.0, anchor: .top)
            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed { isPressed = true }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}
