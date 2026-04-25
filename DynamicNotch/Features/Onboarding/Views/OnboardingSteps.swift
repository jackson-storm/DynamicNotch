//
//  OnboardingSteps.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/13/26.
//

import SwiftUI

enum OnboardingSteps: String, Equatable, CaseIterable {
    case first
    case second
    case third
    case fourth
    
    static let stackID = NotchContentRegistry.Onboarding.stackID
    
    var liveActivityID: String {
        NotchContentRegistry.Onboarding.id(forStep: rawValue)
    }
    
    static func contains(id: String?) -> Bool {
        guard let id else { return false }
        return allCases.contains(where: { $0.liveActivityID == id })
    }
    
    #if DEBUG
    static let debugStackID = NotchContentRegistry.Onboarding.debugStackID
    
    var debugLiveActivityID: String {
        NotchContentRegistry.Onboarding.debugID(forStep: rawValue)
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
        case .fourth:
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
        case .fourth:
            .init(width: baseWidth + 160, height: baseHeight + 140)
        }
    }
}
