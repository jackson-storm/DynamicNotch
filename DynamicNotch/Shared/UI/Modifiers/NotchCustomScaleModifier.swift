//
//  NotchPressModifier.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/14/26.
//

internal import AppKit
import SwiftUI

struct NotchCustomScaleModifier: ViewModifier {
    @ObservedObject var notchViewModel: NotchViewModel
    @Binding var isPressed: Bool
    @State private var pendingExpansionToken: UUID?
    @State private var pressAnimationToken: UUID?
    @State private var pressScale: CGFloat = 1
    let baseSize: CGSize
    
    private let scaleFactor: CGFloat = 1.04
    private let pressPeakDuration: TimeInterval = 0.2
    private let holdToExpandDelay: TimeInterval = 0.2
    
    func body(content: Content) -> some View {
        pressableContent(content)
    }
}

private extension NotchCustomScaleModifier {
    func pressableContent(_ content: Content) -> some View {
        let hitBounds = CGRect(origin: .zero, size: baseSize)
        let isExpandedPresentation = notchViewModel.notchModel.isPresentingExpandedLiveActivity

        return content
            .scaleEffect(
                x: !isExpandedPresentation ? pressScale : 1,
                y: !isExpandedPresentation ? pressScale : 1,
                anchor: .top
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !notchViewModel.notchModel.isPresentingExpandedLiveActivity else {
                            resetPressState(cancelPressAnimation: true)
                            return
                        }

                        let isInsideBounds = hitBounds.contains(value.location)

                        guard isInsideBounds else {
                            resetPressState(cancelPressAnimation: true)
                            return
                        }

                        if !isPressed {
                            isPressed = true
                            startPressAnimation()
                        }

                        scheduleExpansionIfNeeded()
                    }
                    .onEnded { _ in
                        guard !notchViewModel.notchModel.isPresentingExpandedLiveActivity else {
                            resetPressState(cancelPressAnimation: true)
                            return
                        }

                        resetPressState(cancelPressAnimation: false)
                    }
            )
            .onDisappear {
                resetPressState(cancelPressAnimation: true)
            }
    }

    private func startPressAnimation() {
        let token = UUID()
        pressAnimationToken = token
        pressScale = 1

        withAnimation(.easeOut(duration: pressPeakDuration)) {
            pressScale = scaleFactor
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + pressPeakDuration) {
            guard pressAnimationToken == token else { return }

            pressAnimationToken = nil

            withAnimation(.spring(response: 0.30, dampingFraction: 0.5)) {
                pressScale = 1
            }
        }
    }

    private func performPressHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    private func scheduleExpansionIfNeeded() {
        guard pendingExpansionToken == nil,
              notchViewModel.isTapToExpandEnabled,
              notchViewModel.canExpandActiveLiveActivity else {
            return
        }

        let token = UUID()
        pendingExpansionToken = token

        DispatchQueue.main.asyncAfter(deadline: .now() + holdToExpandDelay) {
            guard pendingExpansionToken == token,
                  isPressed,
                  notchViewModel.isTapToExpandEnabled,
                  notchViewModel.canExpandActiveLiveActivity,
                  !notchViewModel.notchModel.isPresentingExpandedLiveActivity else {
                return
            }

            pendingExpansionToken = nil
            performPressHaptic()
            resetPressState(cancelPressAnimation: true)
            notchViewModel.handleActiveContentTap()
        }
    }

    private func resetPressState(cancelPressAnimation: Bool) {
        pendingExpansionToken = nil

        if cancelPressAnimation {
            pressAnimationToken = nil

            if pressScale != 1 {
                withAnimation(.easeOut(duration: 0.12)) {
                    pressScale = 1
                }
            }
        }

        if isPressed {
            isPressed = false
        }
    }
}
