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
    
    @State private var pendingHoldExpansionToken: UUID?
    @State private var pendingHoverExpansionToken: UUID?
    @State private var pressAnimationToken: UUID?
    @State private var initialPressLocation: CGPoint?
    @State private var isPressValidForTap = false
    @State private var didCompleteExpandAction = false
    @State private var isHovering = false
    @State private var pressScale: CGFloat = 1
    
    let baseSize: CGSize
    
    private let scaleFactor: CGFloat = 1.04
    private let tapMovementTolerance: CGFloat = 8
    
    func body(content: Content) -> some View {
        pressableContent(content)
    }
}

private extension NotchCustomScaleModifier {
    func pressableContent(_ content: Content) -> some View {
        let hitBounds = CGRect(origin: .zero, size: baseSize)
        let isExpandedPresentation = notchViewModel.notchModel.isPresentingExpandedLiveActivity
        let isPresentationHidden = notchViewModel.isActivityPresentationHidden

        return content
            .scaleEffect(
                x: !isExpandedPresentation && !isPresentationHidden ? pressScale : 1,
                y: !isExpandedPresentation && !isPresentationHidden ? pressScale : 1,
                anchor: .top
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !notchViewModel.isActivityPresentationHidden,
                              !notchViewModel.notchModel.isPresentingExpandedLiveActivity else {
                            resetInteractionState(cancelScaleAnimation: true)
                            return
                        }

                        let isInsideBounds = hitBounds.contains(value.location)

                        guard isInsideBounds else {
                            isPressValidForTap = false
                            resetInteractionState(cancelScaleAnimation: true)
                            return
                        }

                        if !isPressed {
                            isPressed = true
                            initialPressLocation = value.location
                            isPressValidForTap = true
                            didCompleteExpandAction = false

                            if !shouldUseHoverExpansion {
                                startPressAnimation()
                            }
                        }

                        if let initialPressLocation,
                           distance(from: initialPressLocation, to: value.location) > tapMovementTolerance {
                            isPressValidForTap = false
                            pendingHoldExpansionToken = nil
                        }

                        if isPressValidForTap {
                            schedulePressHoldExpansionIfNeeded()
                        }
                    }
                    .onEnded { value in
                        guard !notchViewModel.isActivityPresentationHidden,
                              !notchViewModel.notchModel.isPresentingExpandedLiveActivity else {
                            resetInteractionState(cancelScaleAnimation: true)
                            didCompleteExpandAction = false
                            return
                        }

                        let isValidPress = hitBounds.contains(value.location) &&
                        isPressValidForTap &&
                        !didCompleteExpandAction

                        resetInteractionState(cancelScaleAnimation: !shouldMaintainHoverScaleAfterRelease)

                        if notchViewModel.shouldExpandActiveContentOnClick && isValidPress {
                            notchViewModel.handleActiveContentTap()
                        } else if isValidPress {
                            notchViewModel.openActiveWindowLink()
                        }

                        didCompleteExpandAction = false
                    }
            )
            .onHover { hovering in
                handleHoverChange(isHovering: hovering)
            }
            .onChange(of: notchViewModel.displayedPresentationID) {
                if notchViewModel.displayedPresentationID == nil {
                    resetInteractionState(cancelScaleAnimation: true)
                }
            }
            .onChange(of: notchViewModel.isActivityPresentationHidden) {
                if notchViewModel.isActivityPresentationHidden {
                    resetInteractionState(cancelScaleAnimation: true)
                }
            }
            .onDisappear {
                resetInteractionState(cancelScaleAnimation: true)
                didCompleteExpandAction = false
            }
    }

    var shouldUseHoverExpansion: Bool {
        notchViewModel.shouldExpandActiveContentOnHover
    }

    var shouldMaintainHoverScaleAfterRelease: Bool {
        shouldUseHoverExpansion && isHovering
    }

    private func startPressAnimation() {
        let token = UUID()
        let pressPeakDuration = notchViewModel.notchPressHoldDuration
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

    private func startHoverAnimation() {
        pressAnimationToken = nil

        withAnimation(.easeOut(duration: min(0.18, notchViewModel.notchHoverExpandDelay))) {
            pressScale = scaleFactor
        }
    }

    private func performExpandHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    private func schedulePressHoldExpansionIfNeeded() {
        guard pendingHoldExpansionToken == nil,
              notchViewModel.shouldExpandActiveContentOnPressAndHold else {
            return
        }

        let token = UUID()
        let holdToExpandDelay = notchViewModel.notchPressHoldDuration
        pendingHoldExpansionToken = token

        DispatchQueue.main.asyncAfter(deadline: .now() + holdToExpandDelay) {
            guard pendingHoldExpansionToken == token,
                  isPressed,
                  notchViewModel.shouldExpandActiveContentOnPressAndHold,
                  !notchViewModel.notchModel.isPresentingExpandedLiveActivity else {
                return
            }

            pendingHoldExpansionToken = nil
            didCompleteExpandAction = true
            performExpandHaptic()
            resetInteractionState(cancelScaleAnimation: true)
            notchViewModel.handleActiveContentTap()
        }
    }

    private func scheduleHoverExpansionIfNeeded() {
        guard pendingHoverExpansionToken == nil,
              isHovering,
              notchViewModel.shouldExpandActiveContentOnHover else {
            return
        }

        let token = UUID()
        let hoverToExpandDelay = notchViewModel.notchHoverExpandDelay
        pendingHoverExpansionToken = token

        DispatchQueue.main.asyncAfter(deadline: .now() + hoverToExpandDelay) {
            guard pendingHoverExpansionToken == token,
                  isHovering,
                  notchViewModel.shouldExpandActiveContentOnHover,
                  !notchViewModel.notchModel.isPresentingExpandedLiveActivity,
                  !notchViewModel.isActivityPresentationHidden else {
                return
            }

            pendingHoverExpansionToken = nil
            didCompleteExpandAction = true
            performExpandHaptic()
            resetInteractionState(cancelScaleAnimation: true)
            notchViewModel.handleActiveContentTap()
        }
    }

    private func handleHoverChange(isHovering: Bool) {
        self.isHovering = isHovering

        guard notchViewModel.shouldExpandActiveContentOnHover,
              !notchViewModel.isActivityPresentationHidden,
              !notchViewModel.notchModel.isPresentingExpandedLiveActivity else {
            if !isHovering {
                resetHoverState()
                if notchViewModel.shouldCollapseActiveContentOnHoverLeaves {
                    notchViewModel.handleOutsideClick()
                }
            }
            return
        }

        if isHovering {
            didCompleteExpandAction = false
            startHoverAnimation()
            scheduleHoverExpansionIfNeeded()
        } else {
            resetHoverState()
            if notchViewModel.shouldCollapseActiveContentOnHoverLeaves {
                notchViewModel.handleOutsideClick()
            }
        }
    }

    private func resetHoverState() {
        pendingHoverExpansionToken = nil
        pressAnimationToken = nil

        if pressScale != 1 {
            withAnimation(.easeOut(duration: 0.12)) {
                pressScale = 1
            }
        }
    }

    private func resetInteractionState(cancelScaleAnimation: Bool) {
        pendingHoldExpansionToken = nil
        pendingHoverExpansionToken = nil
        initialPressLocation = nil
        isPressValidForTap = false

        if cancelScaleAnimation {
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

    private func distance(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let xDistance = end.x - start.x
        let yDistance = end.y - start.y

        return sqrt((xDistance * xDistance) + (yDistance * yDistance))
    }
}
