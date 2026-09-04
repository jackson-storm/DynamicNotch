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
        let damping: Double = 0.75
        let baseResponse: Double
        let blend: Double
        let hideShowDelay: Double
        
        switch preset {
        case .snappy:
            baseResponse = 0.41
            blend = 0.12
            hideShowDelay = 0.28
            
        case .fast:
            baseResponse = 0.44
            blend = 0.15
            hideShowDelay = 0.31
            
        case .balanced:
            baseResponse = 0.47
            blend = 0.18
            hideShowDelay = 0.34
            
        case .slow:
            baseResponse = 0.50
            blend = 0.22
            hideShowDelay = 0.37
            
        case .relaxed:
            baseResponse = 0.53
            blend = 0.25
            hideShowDelay = 0.40
        }
        
        let expandResponse = baseResponse - 0.02
        let closeResponse = baseResponse + 0.08
        
        return Self(
            contentUpdate: .spring(response: baseResponse, blendDuration: blend),
            contentHide: .spring(response: baseResponse, blendDuration: blend),
            contentShow: .spring(response: baseResponse, dampingFraction: damping, blendDuration: blend),
            openContentTransition: .spring(response: baseResponse, dampingFraction: damping, blendDuration: blend),
            
            expandLiveActivity: .spring(response: expandResponse, dampingFraction: damping, blendDuration: blend),
            expandLiveActivityContentTransition: .spring(response: expandResponse, dampingFraction: damping, blendDuration: blend),
            
            closeLiveActivity: .spring(response: closeResponse, blendDuration: blend),
            closeLiveActivityContentTransition: .spring(response: expandResponse, dampingFraction: damping, blendDuration: blend),
            
            stretchReset: .spring(response: baseResponse, blendDuration: blend),
            strokeVisibility: .spring(response: baseResponse, blendDuration: blend),
            notchVisibility: .spring(response: baseResponse, blendDuration: blend),
            focusCloseStretch: .spring(response: baseResponse, dampingFraction: damping, blendDuration: blend),
            
            hideShowDelay: hideShowDelay,
            queuePacingDelay: 0.1
        )
    }
}
