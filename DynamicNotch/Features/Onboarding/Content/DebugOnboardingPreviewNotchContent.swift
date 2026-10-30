//
//  DebugOnboardingPreviewNotchContent.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/31/26.
//

import SwiftUI

#if DEBUG
struct DebugOnboardingPreviewNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id: String
    let stackID = NotchContentRegistry.Onboarding.debugStackID
    let step: OnboardingSteps
    let notchEventCoordinator: NotchEventCoordinator
    
    var allowsCompactPressScaleEffect: Bool = false
    var priority: Int { NotchContentRegistry.Onboarding.priority }
    
    init(step: OnboardingSteps, notchEventCoordinator: NotchEventCoordinator) {
        self.id = step.debugLiveActivityID
        self.step = step
        self.notchEventCoordinator = notchEventCoordinator
    }
    
    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        step.notchSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        step.dynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.25
    }
    
    @MainActor
    func compactView() -> AnyView {
        AnyView(
            OnboardingNotchView(
                step: step,
                onStepChange: { nextStep in
                    notchEventCoordinator.showDebugOnboardingPreview(step: nextStep)
                },
                onFinish: {
                    notchEventCoordinator.hideOnboarding()
                }
            )
        )
    }
}
#endif
