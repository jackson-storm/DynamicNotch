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

    static let `default`: Self = .balanced

    static let balanced: Self = {
        let damping: Double = 0.75
        let expandDamping: Double = 0.75
        
        let baseResponse: Double = 0.50
        let blend: Double = 1.0
        let hideShowDelay: Double = 0.32
        
        return Self(
            contentUpdate: .spring(response: baseResponse, dampingFraction: damping, blendDuration: blend),
            contentHide: .spring(response: baseResponse, dampingFraction: damping, blendDuration: blend),
            contentShow: .spring(response: baseResponse, dampingFraction: damping, blendDuration: blend),
            openContentTransition: .spring(response: baseResponse, dampingFraction: damping, blendDuration: blend),
            
            expandLiveActivity: .spring(response: baseResponse, dampingFraction: expandDamping, blendDuration: blend),
            expandLiveActivityContentTransition: .spring(response: baseResponse, dampingFraction: expandDamping, blendDuration: blend),
            
            closeLiveActivity: .spring(response: baseResponse, blendDuration: blend),
            closeLiveActivityContentTransition: .spring(response: baseResponse, dampingFraction: damping, blendDuration: blend),
            
            stretchReset: .spring(response: baseResponse, blendDuration: blend),
            strokeVisibility: .spring(response: baseResponse, blendDuration: blend),
            notchVisibility: .spring(response: baseResponse, blendDuration: blend),
            focusCloseStretch: .spring(response: baseResponse, blendDuration: blend),
            
            hideShowDelay: hideShowDelay,
            queuePacingDelay: 0.1
        )
    }()

    static func preset(_ preset: NotchAnimationPreset = .balanced) -> Self {
        .balanced
    }
}
