//
//  extension+View.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/10/26.
//

import SwiftUI

extension View {
    func customNotchPressable(
        notchViewModel: NotchViewModel,
        isPressed: Binding<Bool>,
        baseSize: CGSize,
        isEnabled: Bool = true
    ) -> some View {
        modifier(
            NotchCustomScaleModifier(
                notchViewModel: notchViewModel,
                isPressed: isPressed,
                baseSize: baseSize,
                isEnabled: isEnabled
            )
        )
    }

    func customNotchMouseSwipeable(notchViewModel: NotchViewModel, isEnabled: Bool = true) -> some View {
        modifier(
            NotchMouseSwipeModifier(
                notchViewModel: notchViewModel,
                isEnabled: isEnabled
            )
        )
    }

    func customNotchSwipeDismissable(notchViewModel: NotchViewModel, isEnabled: Bool = true) -> some View {
        modifier(
            NotchSwipeDismissModifier(
                notchViewModel: notchViewModel,
                isEnabled: isEnabled
            )
        )
    }
}
