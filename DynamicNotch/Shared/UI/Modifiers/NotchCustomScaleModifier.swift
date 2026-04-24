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
    @State private var pendingExpansionToken: UUID?
    let baseSize: CGSize
    
    private let scaleFactor: CGFloat = 1.04
    private let holdToExpandDelay: TimeInterval = 0.18
    
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
                x: isPressed && !isExpandedPresentation ? scaleFactor : 1,
                y: isPressed && !isExpandedPresentation ? scaleFactor : 1,
                anchor: .top
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !notchViewModel.notchModel.isPresentingExpandedLiveActivity else {
                            resetPressState()
                            return
                        }

                        let isInsideBounds = hitBounds.contains(value.location)

                        guard isInsideBounds else {
                            resetPressState()
                            return
                        }

                        if !isPressed {
                            isPressed = true
                        }

                        scheduleExpansionIfNeeded()
                    }
                    .onEnded { _ in
                        guard !notchViewModel.notchModel.isPresentingExpandedLiveActivity else {
                            resetPressState()
                            return
                        }

                        resetPressState()
                    }
            )
            .onDisappear {
                resetPressState()
            }
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
            isPressed = false
            notchViewModel.handleActiveContentTap()
        }
    }

    private func resetPressState() {
        pendingExpansionToken = nil

        if isPressed {
            isPressed = false
        }
    }
}
