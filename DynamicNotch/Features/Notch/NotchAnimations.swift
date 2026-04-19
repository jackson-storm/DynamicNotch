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

    static let `default` = preset(.fast)

    static func preset(_ preset: NotchAnimationPreset) -> Self {
        switch preset {
        case .snappy:
            return Self(
                contentUpdate: .spring(response: 0.4),
                contentHide: .spring(response: 0.46),
                contentShow: .spring(response: 0.31),
                stretchReset: .spring(response: 0.6, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.36, dampingFraction: 0.8),
                strokeVisibility: .spring(duration: 0.41),
                notchVisibility: .spring(duration: 0.41),
                contentTransition: .spring(duration: 0.41),
                hideShowDelay: 0.31,
                queuePacingDelay: 0.1
            )

        case .fast:
            return Self(
                contentUpdate: .spring(response: 0.4),
                contentHide: .spring(response: 0.48),
                contentShow: .spring(response: 0.33),
                stretchReset: .spring(response: 0.6, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.38, dampingFraction: 0.8),
                strokeVisibility: .spring(duration: 0.43),
                notchVisibility: .spring(duration: 0.43),
                contentTransition: .spring(duration: 0.43),
                hideShowDelay: 0.33,
                queuePacingDelay: 0.1
            )

        case .balanced:
            return Self(
                contentUpdate: .spring(response: 0.4),
                contentHide: .spring(response: 0.5),
                contentShow: .spring(response: 0.35),
                stretchReset: .spring(response: 0.6, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.4, dampingFraction: 0.8),
                strokeVisibility: .spring(duration: 0.45),
                notchVisibility: .spring(duration: 0.45),
                contentTransition: .spring(duration: 0.45),
                hideShowDelay: 0.35,
                queuePacingDelay: 0.1
            )

        case .slow:
            return Self(
                contentUpdate: .spring(response: 0.4),
                contentHide: .spring(response: 0.52),
                contentShow: .spring(response: 0.37),
                stretchReset: .spring(response: 0.6, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.42, dampingFraction: 0.8),
                strokeVisibility: .spring(duration: 0.47),
                notchVisibility: .spring(duration: 0.47),
                contentTransition: .spring(duration: 0.47),
                hideShowDelay: 0.37,
                queuePacingDelay: 0.1
            )

        case .relaxed:
            return Self(
                contentUpdate: .spring(response: 0.4),
                contentHide: .spring(response: 0.54),
                contentShow: .spring(response: 0.39),
                stretchReset: .spring(response: 0.6, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.44, dampingFraction: 0.8),
                strokeVisibility: .spring(duration: 0.49),
                notchVisibility: .spring(duration: 0.49),
                contentTransition: .spring(duration: 0.49),
                hideShowDelay: 0.39,
                queuePacingDelay: 0.1
            )
        }
    }
}
