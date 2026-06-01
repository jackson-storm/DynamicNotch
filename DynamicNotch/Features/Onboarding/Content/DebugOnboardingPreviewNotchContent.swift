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
    
    var priority: Int { NotchContentRegistry.Onboarding.priority }
    
    init(step: OnboardingSteps, notchEventCoordinator: NotchEventCoordinator) {
        self.id = step.debugLiveActivityID
        self.step = step
        self.notchEventCoordinator = notchEventCoordinator
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        step.notchSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }
    
    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        step.dynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
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
