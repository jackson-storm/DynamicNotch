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
        baseSize: CGSize
    ) -> some View {
        modifier(
            NotchCustomScaleModifier(
                notchViewModel: notchViewModel,
                isPressed: isPressed,
                baseSize: baseSize
            )
        )
    }

    func customNotchMouseSwipeable(
        notchViewModel: NotchViewModel
    ) -> some View {
        modifier(
            NotchMouseSwipeModifier(
                notchViewModel: notchViewModel
            )
        )
    }

    func customNotchSwipeDismissable(
        notchViewModel: NotchViewModel
    ) -> some View {
        modifier(
            NotchSwipeDismissModifier(
                notchViewModel: notchViewModel
            )
        )
    }
}
