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
    let stretchReset: Animation
    let strokeVisibility: Animation
    let notchVisibility: Animation
    let hideShowDelay: TimeInterval
    let queuePacingDelay: TimeInterval

    static let `default` = preset(.balanced)

    static func preset(_ preset: NotchAnimationPreset) -> Self {
        switch preset {
        case .snappy:
            return Self(
                contentUpdate: .spring(response: 0.41),
                contentHide: .spring(response: 0.41, dampingFraction: 0.7),
                contentShow: .spring(response: 0.41, dampingFraction: 0.7),
                openContentTransition: .spring(response: 0.44, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.34, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.39, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.41),
                strokeVisibility: .spring(response: 0.41),
                notchVisibility: .spring(response: 0.41),
                hideShowDelay: 0.29,
                queuePacingDelay: 0.1
            )

        case .fast:
            return Self(
                contentUpdate: .spring(response: 0.44),
                contentHide: .spring(response: 0.44, dampingFraction: 0.7),
                contentShow: .spring(response: 0.44, dampingFraction: 0.7),
                openContentTransition: .spring(response: 0.47, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.37, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.42, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.44),
                strokeVisibility: .spring(response: 0.44),
                notchVisibility: .spring(response: 0.44),
                hideShowDelay: 0.32,
                queuePacingDelay: 0.1
            )

        case .balanced:
            return Self(
                contentUpdate: .spring(response: 0.47),
                contentHide: .spring(response: 0.47, dampingFraction: 0.7),
                contentShow: .spring(response: 0.47, dampingFraction: 0.7),
                openContentTransition: .spring(response: 0.50, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.40, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.45, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.47),
                strokeVisibility: .spring(response: 0.47),
                notchVisibility: .spring(response: 0.47),
                hideShowDelay: 0.35,
                queuePacingDelay: 0.1
            )

        case .slow:
            return Self(
                contentUpdate: .spring(response: 0.50),
                contentHide: .spring(response: 0.50, dampingFraction: 0.7),
                contentShow: .spring(response: 0.50, dampingFraction: 0.7),
                openContentTransition: .spring(response: 0.53, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.43, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.48, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.50),
                strokeVisibility: .spring(response: 0.50),
                notchVisibility: .spring(response: 0.50),
                hideShowDelay: 0.38,
                queuePacingDelay: 0.1
            )

        case .relaxed:
            return Self(
                contentUpdate: .spring(response: 0.53),
                contentHide: .spring(response: 0.53, dampingFraction: 0.7),
                contentShow: .spring(response: 0.53, dampingFraction: 0.7),
                openContentTransition: .spring(response: 0.56, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.46, dampingFraction: 0.8),
                expandLiveActivityContentTransition: .spring(response: 0.51, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.53),
                strokeVisibility: .spring(response: 0.53),
                notchVisibility: .spring(response: 0.53),
                hideShowDelay: 0.41,
                queuePacingDelay: 0.1
            )
        }
    }
}
