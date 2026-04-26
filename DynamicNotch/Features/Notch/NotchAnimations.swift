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
    let stretchReset: Animation
    let expandLiveActivity: Animation
    let strokeVisibility: Animation
    let notchVisibility: Animation
    let openContentTransition: Animation
    let expandLiveActivityContentTransition: Animation
    let hideShowDelay: TimeInterval
    let queuePacingDelay: TimeInterval

    static let `default` = preset(.balanced)

    static func preset(_ preset: NotchAnimationPreset) -> Self {
        switch preset {
        case .snappy:
            return Self(
                contentUpdate: .spring(response: 0.36),
                contentHide: .spring(response: 0.36, dampingFraction: 0.8),
                contentShow: .spring(response: 0.36, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.36, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.31, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.36),
                notchVisibility: .spring(response: 0.36),
                openContentTransition: .spring(response: 0.46, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.36, dampingFraction: 0.8),
                hideShowDelay: 0.26,
                queuePacingDelay: 0.1
            )

        case .fast:
            return Self(
                contentUpdate: .spring(response: 0.39),
                contentHide: .spring(response: 0.39, dampingFraction: 0.8),
                contentShow: .spring(response: 0.39, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.39, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.34, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.39),
                notchVisibility: .spring(response: 0.39),
                openContentTransition: .spring(response: 0.49, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.39, dampingFraction: 0.8),
                hideShowDelay: 0.29,
                queuePacingDelay: 0.1
            )

        case .balanced:
            return Self(
                contentUpdate: .spring(response: 0.42),
                contentHide: .spring(response: 0.42, dampingFraction: 0.8),
                contentShow: .spring(response: 0.42, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.42, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.37, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.42),
                notchVisibility: .spring(response: 0.42),
                openContentTransition: .spring(response: 0.52, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.42, dampingFraction: 0.8),
                hideShowDelay: 0.32,
                queuePacingDelay: 0.1
            )

        case .slow:
            return Self(
                contentUpdate: .spring(response: 0.45),
                contentHide: .spring(response: 0.45, dampingFraction: 0.8),
                contentShow: .spring(response: 0.45, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.45, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.40, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.45),
                notchVisibility: .spring(response: 0.45),
                openContentTransition: .spring(response: 0.55, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.45, dampingFraction: 0.8),
                hideShowDelay: 0.35,
                queuePacingDelay: 0.1
            )

        case .relaxed:
            return Self(
                contentUpdate: .spring(response: 0.48),
                contentHide: .spring(response: 0.48, dampingFraction: 0.8),
                contentShow: .spring(response: 0.48, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.48, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.43, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.48),
                notchVisibility: .spring(response: 0.48),
                openContentTransition: .spring(response: 0.58, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.48, dampingFraction: 0.8),
                hideShowDelay: 0.38,
                queuePacingDelay: 0.1
            )
        }
    }
}
