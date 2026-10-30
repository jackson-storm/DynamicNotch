//
//  OnboardingView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/20/26.
//

import SwiftUI

enum OnboardingEvent: Equatable {
    case onboarding
}

struct OnboardingNotchContent : NotchContentProtocol, DynamicIslandCustomizable {
    let id: String
    let stackID = OnboardingSteps.stackID
    let step: OnboardingSteps
    let notchEventCoordinator: NotchEventCoordinator
    
    var priority: Int { NotchContentRegistry.Onboarding.priority }
    var allowsCompactPressScaleEffect: Bool = false
    
    init(step: OnboardingSteps, notchEventCoordinator: NotchEventCoordinator) {
        self.id = step.liveActivityID
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
                    notchEventCoordinator.showOnboarding(step: nextStep)
                },
                onFinish: {
                    notchEventCoordinator.finishOnboarding()
                }
            )
        )
    }
}
