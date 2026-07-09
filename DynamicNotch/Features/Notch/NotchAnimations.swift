//
//  NotchAnimations.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/29/26.
//

import SwiftUI

struct NotchAnimations {
    let contentUpdate: Animation
    let contentHide: Animation
    let contentShow: Animation
    let openContentTransition: Animation
    let expandLiveActivity: Animation
    let expandLiveActivityContentTransition: Animation
    let closeLiveActivity: Animation
    let closeLiveActivityContentTransition: Animation
    let stretchReset: Animation
    let strokeVisibility: Animation
    let notchVisibility: Animation
    let hideShowDelay: TimeInterval
    let queuePacingDelay: TimeInterval

    static let `default` = preset(.balanced)

    static func preset(_ preset: NotchAnimationPreset) -> Self {
        let damping: Double = 0.77
        
        switch preset {
        case .snappy:
            return Self(
                contentUpdate: .spring(response: 0.41),
                contentHide: .spring(response: 0.41),
                contentShow: .spring(response: 0.41, dampingFraction: damping),
                openContentTransition: .spring(response: 0.41, dampingFraction: damping),
                
                expandLiveActivity: .spring(response: 0.39, dampingFraction: damping),
                expandLiveActivityContentTransition: .spring(response: 0.39, dampingFraction: damping),
                
                closeLiveActivity: .spring(response: 0.49),
                closeLiveActivityContentTransition: .spring(response: 0.39, dampingFraction: damping),
                
                stretchReset: .spring(response: 0.41),
                strokeVisibility: .spring(response: 0.41),
                notchVisibility: .spring(response: 0.41),
                
                hideShowDelay: 0.28,
                queuePacingDelay: 0.1
            )

        case .fast:
            return Self(
                contentUpdate: .spring(response: 0.44),
                contentHide: .spring(response: 0.44),
                contentShow: .spring(response: 0.44, dampingFraction: damping),
                openContentTransition: .spring(response: 0.44, dampingFraction: damping),
                
                expandLiveActivity: .spring(response: 0.42, dampingFraction: damping),
                expandLiveActivityContentTransition: .spring(response: 0.42, dampingFraction: damping),
                
                closeLiveActivity: .spring(response: 0.52),
                closeLiveActivityContentTransition: .spring(response: 0.42, dampingFraction: damping),
                
                stretchReset: .spring(response: 0.44),
                strokeVisibility: .spring(response: 0.44),
                notchVisibility: .spring(response: 0.44),
                
                hideShowDelay: 0.31,
                queuePacingDelay: 0.1
            )

        case .balanced:
            return Self(
                contentUpdate: .spring(response: 0.47),
                contentHide: .spring(response: 0.47),
                contentShow: .spring(response: 0.47, dampingFraction: damping),
                openContentTransition: .spring(response: 0.47, dampingFraction: damping),
                
                expandLiveActivity: .spring(response: 0.45, dampingFraction: damping),
                expandLiveActivityContentTransition: .spring(response: 0.45, dampingFraction: damping),
                
                closeLiveActivity: .spring(response: 0.55),
                closeLiveActivityContentTransition: .spring(response: 0.45, dampingFraction: damping),
                
                stretchReset: .spring(response: 0.47),
                strokeVisibility: .spring(response: 0.47),
                notchVisibility: .spring(response: 0.47),
                
                hideShowDelay: 0.34,
                queuePacingDelay: 0.1
            )

        case .slow:
            return Self(
                contentUpdate: .spring(response: 0.50),
                contentHide: .spring(response: 0.50),
                contentShow: .spring(response: 0.50, dampingFraction: damping),
                openContentTransition: .spring(response: 0.50, dampingFraction: damping),
                
                expandLiveActivity: .spring(response: 0.48, dampingFraction: damping),
                expandLiveActivityContentTransition: .spring(response: 0.48, dampingFraction: damping),
                
                closeLiveActivity: .spring(response: 0.58),
                closeLiveActivityContentTransition: .spring(response: 0.48, dampingFraction: damping),
                
                stretchReset: .spring(response: 0.50),
                strokeVisibility: .spring(response: 0.50),
                notchVisibility: .spring(response: 0.50),
                
                hideShowDelay: 0.37,
                queuePacingDelay: 0.1
            )

        case .relaxed:
            return Self(
                contentUpdate: .spring(response: 0.53),
                contentHide: .spring(response: 0.53),
                contentShow: .spring(response: 0.53, dampingFraction: damping),
                openContentTransition: .spring(response: 0.53, dampingFraction: damping),
                
                expandLiveActivity: .spring(response: 0.51, dampingFraction: damping),
                expandLiveActivityContentTransition: .spring(response: 0.51, dampingFraction: damping),
                
                closeLiveActivity: .spring(response: 0.61),
                closeLiveActivityContentTransition: .spring(response: 0.51, dampingFraction: damping),
                
                stretchReset: .spring(response: 0.53),
                strokeVisibility: .spring(response: 0.53),
                notchVisibility: .spring(response: 0.53),
                
                hideShowDelay: 0.40,
                queuePacingDelay: 0.1
            )
        }
    }
}
