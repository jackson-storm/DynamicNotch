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
    private let tapMovementTolerance: CGFloat = 6
    
    func body(content: Content) -> some View {
        let hitBounds = CGRect(origin: .zero, size: baseSize)
        
        content
            .scaleEffect(
                x: isPressed ? scaleFactor : 1,
                y: isPressed ? scaleFactor : 1,
                anchor: .top
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let shouldBePressed = hitBounds.contains(value.location)
                        guard isPressed != shouldBePressed else { return }
                        isPressed = shouldBePressed
                    }
                    .onEnded { value in
                        let shouldTriggerTap = hitBounds.contains(value.location) && isTapLike(value.translation)

                        if isPressed {
                            isPressed = false
                        }

                        guard shouldTriggerTap, notchViewModel.isTapToExpandEnabled else { return }

                        if notchViewModel.canExpandActiveLiveActivity {
                            notchViewModel.handleActiveContentTap()
                            return
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + tapTriggerDelay) {
                            notchViewModel.handleActiveContentTap()
                        }
                    }
            )
    }
}

private extension NotchCustomScaleModifier {
    private func isTapLike(_ translation: CGSize) -> Bool {
        abs(translation.width) <= tapMovementTolerance &&
        abs(translation.height) <= tapMovementTolerance
    }
}
