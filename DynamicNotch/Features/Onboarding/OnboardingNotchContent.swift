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

enum OnboardingSteps: String, Equatable, CaseIterable {
    case first
    case second
    case third
    
    static let stackID = "onboarding"
    
    var liveActivityID: String {
        "\(Self.stackID).\(rawValue)"
    }
    
    static func contains(id: String?) -> Bool {
        guard let id else { return false }
        return allCases.contains(where: { $0.liveActivityID == id })
    }
    
    #if DEBUG
    static let debugStackID = "onboarding.debug"
    
    var debugLiveActivityID: String {
        "\(Self.debugStackID).\(rawValue)"
    }
    
    static func containsDebug(id: String?) -> Bool {
        guard let id else { return false }
        return allCases.contains(where: { $0.debugLiveActivityID == id })
    }
    #endif
    
    var offsetXTransition: CGFloat {
        switch self {
        case .first:
            return -50
        case .second:
            return -80
        case .third:
            return -80
        }
    }
    
    func notchSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        switch self {
        case .first:
            .init(width: baseWidth + 70, height: baseHeight + 120)
        case .second:
            .init(width: baseWidth + 160, height: baseHeight + 140)
        case .third:
            .init(width: baseWidth + 160, height: baseHeight + 140)
        }
    }
}

struct OnboardingNotchContent : NotchContentProtocol {
    let id: String
    let stackID = OnboardingSteps.stackID
    let step: OnboardingSteps
    let notchEventCoordinator: NotchEventCoordinator
    
    var priority: Int { 100 }
    
    var offsetXTransition: CGFloat { step.offsetXTransition }
    var offsetYTransition: CGFloat { -90 }
    
    init(step: OnboardingSteps, notchEventCoordinator: NotchEventCoordinator) {
        self.id = step.liveActivityID
        self.step = step
        self.notchEventCoordinator = notchEventCoordinator
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        step.notchSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }
    
    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        return (top: 24, bottom: 36)
    }
    
    @MainActor
    func makeView() -> AnyView {
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
