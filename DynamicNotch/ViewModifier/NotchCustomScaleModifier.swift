//
//  NotchPressModifier.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

import SwiftUI

struct NotchCustomScaleModifier: ViewModifier {
    @Binding var isPressed: Bool
    let baseSize: CGSize
    
    private let scaleFactor: CGFloat = 1.04
    
    func body(content: Content) -> some View {
        let pressedHeight = baseSize.height * scaleFactor
        let pressedWidth = baseSize.width * scaleFactor
        
        content
            .frame(
                width: isPressed ? pressedWidth : baseSize.width,
                height: isPressed ? pressedHeight : baseSize.height
            )
            .frame(height: baseSize.height, alignment: .top)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                self.isPressed = pressing
            }, perform: {})
    }
}

extension View {
    func customNotchPressable(isPressed: Binding<Bool>, baseSize: CGSize) -> some View {
        modifier(NotchCustomScaleModifier(isPressed: isPressed, baseSize: baseSize))
    }
}
