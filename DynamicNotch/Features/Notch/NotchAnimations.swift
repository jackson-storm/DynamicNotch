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
    let focusCloseStretch: Animation
    let hideShowDelay: TimeInterval
    let queuePacingDelay: TimeInterval

    static let `default` = preset(.balanced)

    static func preset(_ preset: NotchAnimationPreset) -> Self {
        let damping: Double = 0.77
        
        switch preset {
        case .snappy:
            let blend: Double = 0.12
            return Self(
                contentUpdate: .spring(response: 0.41, blendDuration: blend),
                contentHide: .spring(response: 0.41, blendDuration: blend),
                contentShow: .spring(response: 0.41, dampingFraction: damping, blendDuration: blend),
                openContentTransition: .spring(response: 0.41, dampingFraction: damping, blendDuration: blend),
                
                expandLiveActivity: .spring(response: 0.39, dampingFraction: damping, blendDuration: blend),
                expandLiveActivityContentTransition: .spring(response: 0.39, dampingFraction: damping, blendDuration: blend),
                
                closeLiveActivity: .spring(response: 0.49, blendDuration: blend),
                closeLiveActivityContentTransition: .spring(response: 0.39, dampingFraction: damping, blendDuration: blend),
                
                stretchReset: .spring(response: 0.41, blendDuration: blend),
                strokeVisibility: .spring(response: 0.41, blendDuration: blend),
                notchVisibility: .spring(response: 0.41, blendDuration: blend),
                focusCloseStretch: .spring(response: 0.41, dampingFraction: damping, blendDuration: blend),
                
                hideShowDelay: 0.28,
                queuePacingDelay: 0.1
            )

        case .fast:
            let blend: Double = 0.15
            return Self(
                contentUpdate: .spring(response: 0.44, blendDuration: blend),
                contentHide: .spring(response: 0.44, blendDuration: blend),
                contentShow: .spring(response: 0.44, dampingFraction: damping, blendDuration: blend),
                openContentTransition: .spring(response: 0.44, dampingFraction: damping, blendDuration: blend),
                
                expandLiveActivity: .spring(response: 0.42, dampingFraction: damping, blendDuration: blend),
                expandLiveActivityContentTransition: .spring(response: 0.42, dampingFraction: damping, blendDuration: blend),
                
                closeLiveActivity: .spring(response: 0.52, blendDuration: blend),
                closeLiveActivityContentTransition: .spring(response: 0.42, dampingFraction: damping, blendDuration: blend),
                
                stretchReset: .spring(response: 0.44, blendDuration: blend),
                strokeVisibility: .spring(response: 0.44, blendDuration: blend),
                notchVisibility: .spring(response: 0.44, blendDuration: blend),
                focusCloseStretch: .spring(response: 0.44, dampingFraction: damping, blendDuration: blend),
                
                hideShowDelay: 0.31,
                queuePacingDelay: 0.1
            )

        case .balanced:
            let blend: Double = 0.18
            return Self(
                contentUpdate: .spring(response: 0.47, blendDuration: blend),
                contentHide: .spring(response: 0.47, blendDuration: blend),
                contentShow: .spring(response: 0.47, dampingFraction: damping, blendDuration: blend),
                openContentTransition: .spring(response: 0.47, dampingFraction: damping, blendDuration: blend),
                
                expandLiveActivity: .spring(response: 0.45, dampingFraction: damping, blendDuration: blend),
                expandLiveActivityContentTransition: .spring(response: 0.45, dampingFraction: damping, blendDuration: blend),
                
                closeLiveActivity: .spring(response: 0.55, blendDuration: blend),
                closeLiveActivityContentTransition: .spring(response: 0.45, dampingFraction: damping, blendDuration: blend),
                
                stretchReset: .spring(response: 0.47, blendDuration: blend),
                strokeVisibility: .spring(response: 0.47, blendDuration: blend),
                notchVisibility: .spring(response: 0.47, blendDuration: blend),
                focusCloseStretch: .spring(response: 0.47, dampingFraction: damping, blendDuration: blend),
                
                hideShowDelay: 0.34,
                queuePacingDelay: 0.1
            )

        case .slow:
            let blend: Double = 0.22
            return Self(
                contentUpdate: .spring(response: 0.50, blendDuration: blend),
                contentHide: .spring(response: 0.50, blendDuration: blend),
                contentShow: .spring(response: 0.50, dampingFraction: damping, blendDuration: blend),
                openContentTransition: .spring(response: 0.50, dampingFraction: damping, blendDuration: blend),
                
                expandLiveActivity: .spring(response: 0.48, dampingFraction: damping, blendDuration: blend),
                expandLiveActivityContentTransition: .spring(response: 0.48, dampingFraction: damping, blendDuration: blend),
                
                closeLiveActivity: .spring(response: 0.58, blendDuration: blend),
                closeLiveActivityContentTransition: .spring(response: 0.48, dampingFraction: damping, blendDuration: blend),
                
                stretchReset: .spring(response: 0.50, blendDuration: blend),
                strokeVisibility: .spring(response: 0.50, blendDuration: blend),
                notchVisibility: .spring(response: 0.50, blendDuration: blend),
                focusCloseStretch: .spring(response: 0.50, dampingFraction: damping, blendDuration: blend),
                
                hideShowDelay: 0.37,
                queuePacingDelay: 0.1
            )

        case .relaxed:
            let blend: Double = 0.25
            return Self(
                contentUpdate: .spring(response: 0.53, blendDuration: blend),
                contentHide: .spring(response: 0.53, blendDuration: blend),
                contentShow: .spring(response: 0.53, dampingFraction: damping, blendDuration: blend),
                openContentTransition: .spring(response: 0.53, dampingFraction: damping, blendDuration: blend),
                
                expandLiveActivity: .spring(response: 0.51, dampingFraction: damping, blendDuration: blend),
                expandLiveActivityContentTransition: .spring(response: 0.51, dampingFraction: damping, blendDuration: blend),
                
                closeLiveActivity: .spring(response: 0.61, blendDuration: blend),
                closeLiveActivityContentTransition: .spring(response: 0.51, dampingFraction: damping, blendDuration: blend),
                
                stretchReset: .spring(response: 0.53, blendDuration: blend),
                strokeVisibility: .spring(response: 0.53, blendDuration: blend),
                notchVisibility: .spring(response: 0.53, blendDuration: blend),
                focusCloseStretch: .spring(response: 0.53, dampingFraction: damping, blendDuration: blend),
                
                hideShowDelay: 0.40,
                queuePacingDelay: 0.1
            )
        }
    }
}
