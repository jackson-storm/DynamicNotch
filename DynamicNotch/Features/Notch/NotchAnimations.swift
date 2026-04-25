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
    let contentTransition: Animation
    let hideShowDelay: TimeInterval
    let queuePacingDelay: TimeInterval

    static let `default` = preset(.balanced)

    static func preset(_ preset: NotchAnimationPreset) -> Self {
        switch preset {
        case .snappy:
            return Self(
                contentUpdate: .spring(response: 0.39),
                contentHide: .spring(response: 0.39),
                contentShow: .spring(response: 0.39, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.39, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.34, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.39),
                notchVisibility: .spring(response: 0.39),
                contentTransition: .spring(response: 0.39),
                hideShowDelay: 0.34,
                queuePacingDelay: 0.1
            )

        case .fast:
            return Self(
                contentUpdate: .spring(response: 0.42),
                contentHide: .spring(response: 0.42),
                contentShow: .spring(response: 0.42, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.42, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.37, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.42),
                notchVisibility: .spring(response: 0.42),
                contentTransition: .spring(response: 0.42),
                hideShowDelay: 0.37,
                queuePacingDelay: 0.1
            )

        case .balanced:
            return Self(
                contentUpdate: .spring(response: 0.45),
                contentHide: .spring(response: 0.45),
                contentShow: .spring(response: 0.45, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.45, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.40, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.45),
                notchVisibility: .spring(response: 0.45),
                contentTransition: .spring(response: 0.45),
                hideShowDelay: 0.4,
                queuePacingDelay: 0.1
            )

        case .slow:
            return Self(
                contentUpdate: .spring(response: 0.48),
                contentHide: .spring(response: 0.48),
                contentShow: .spring(response: 0.48, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.48, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.43, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.48),
                notchVisibility: .spring(response: 0.48),
                contentTransition: .spring(response: 0.48),
                hideShowDelay: 0.43,
                queuePacingDelay: 0.1
            )

        case .relaxed:
            return Self(
                contentUpdate: .spring(response: 0.51),
                contentHide: .spring(response: 0.51),
                contentShow: .spring(response: 0.51, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.51, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.46, dampingFraction: 0.8),
                strokeVisibility: .spring(response: 0.51),
                notchVisibility: .spring(response: 0.51),
                contentTransition: .spring(response: 0.51),
                hideShowDelay: 0.46,
                queuePacingDelay: 0.1
            )
        }
    }
}
