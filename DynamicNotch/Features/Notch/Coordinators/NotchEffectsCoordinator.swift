//
//  NotchEffectsCoordinator.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 11/10/26.
//

import SwiftUI
import Combine

@MainActor
final class NotchEffectsCoordinator: ObservableObject {
    @Published var focusCloseStretchWidth: CGFloat = 0.0
    @Published var focusCloseStretchHeight: CGFloat = 0.0
    @Published var notchPulseWidth: CGFloat = 0.0
    @Published var notchPulseHeight: CGFloat = 0.0
    @Published var isPressed = false
    @Published var pressScale: CGFloat = 1.0

    private var notchPulseResetWorkItem: DispatchWorkItem?
    private var isFocusCloseAnimating = false

    func pulseNotch(widthOffset: CGFloat = 30.0, heightOffset: CGFloat = 10.0) {
        notchPulseResetWorkItem?.cancel()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            self.notchPulseWidth = widthOffset
            self.notchPulseHeight = heightOffset
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                self.notchPulseWidth = 0
                self.notchPulseHeight = 0
            }
        }
        notchPulseResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
    }

    func triggerFocusCloseAnimation(
        presentedSize: CGSize,
        animations: NotchAnimations,
        completion: @escaping () -> Void
    ) {
        guard !isFocusCloseAnimating else {
            completion()
            return
        }
        isFocusCloseAnimating = true

        let currentWidth = presentedSize.width
        let currentHeight = presentedSize.height

        let compressWidth = -max(20, currentWidth * 0.2)
        let stretchHeight = max(40, currentHeight * 0.2)

        withAnimation(animations.focusDismissBounce) {
            self.focusCloseStretchWidth = compressWidth
            self.focusCloseStretchHeight = stretchHeight
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(animations.focusDismissBounce) {
                self.focusCloseStretchWidth = 0
                self.focusCloseStretchHeight = 0
            }
            completion()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.isFocusCloseAnimating = false
            }
        }
    }

    func shouldApplyPressScale(
        isSwipeInteractionActive: Bool,
        displayedContent: NotchContentProtocol?,
        isDisplayingExpandedLiveActivity: Bool
    ) -> Bool {
        guard !isSwipeInteractionActive else { return false }
        guard let content = displayedContent else { return true }
        guard !isDisplayingExpandedLiveActivity else { return false }

        return content.allowsPressScaleEffect && content.allowsCompactPressScaleEffect
    }
}
