//
//  NotchPressModifier.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

import SwiftUI

struct NotchCustomScaleModifier: ViewModifier {
    @ObservedObject var notchViewModel: NotchViewModel
    @Binding var isPressed: Bool
    let baseSize: CGSize
    
    private let scaleFactor: CGFloat = 1.04
    private let tapTriggerDelay: TimeInterval = 0.12
    
    func body(content: Content) -> some View {
        let hitBounds = CGRect(origin: .zero, size: baseSize)
        
        content
            .scaleEffect(
                x: isPressed ? scaleFactor : 1,
                y: isPressed ? scaleFactor : 1,
                anchor: .top
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let shouldAnimatePress = !notchViewModel.canExpandActiveLiveActivity
                        if !shouldAnimatePress {
                            if isPressed {
                                isPressed = false
                            }
                            return
                        }

                        let shouldBePressed = hitBounds.contains(value.location)
                        guard isPressed != shouldBePressed else { return }
                        isPressed = shouldBePressed
                    }
                    .onEnded { value in
                        let shouldAnimatePress = !notchViewModel.canExpandActiveLiveActivity
                        let shouldTriggerTap = hitBounds.contains(value.location)

                        if shouldAnimatePress {
                            guard isPressed || shouldTriggerTap else { return }
                            isPressed = false
                        } else if isPressed {
                            isPressed = false
                        }

                        guard shouldTriggerTap else { return }

                        if !shouldAnimatePress {
                            notchViewModel.handleActiveContentTap()
                            return
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + tapTriggerDelay) {
                            notchViewModel.handleActiveContentTap()
                        }
                    }
            , including: .gesture)
    }
}
