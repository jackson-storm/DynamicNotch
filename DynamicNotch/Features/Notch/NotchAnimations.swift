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

    static let `default` = preset(.balanced)

    static func preset(_ preset: NotchAnimationPreset) -> Self {
        switch preset {
        case .snappy:
            return Self(
                contentUpdate: .spring(response: 0.28, dampingFraction: 0.82),
                contentHide: .spring(response: 0.34, dampingFraction: 0.9),
                contentShow: .spring(response: 0.3, dampingFraction: 0.82),
                stretchReset: .spring(response: 0.26, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.3, dampingFraction: 0.82),
                strokeVisibility: .smooth(duration: 0.2),
                notchVisibility: .smooth(duration: 0.3),
                contentTransition: .smooth(duration: 0.24)
            )

        case .fast:
            return Self(
                contentUpdate: .spring(response: 0.34, dampingFraction: 0.82),
                contentHide: .spring(response: 0.42, dampingFraction: 0.9),
                contentShow: .spring(response: 0.35, dampingFraction: 0.82),
                stretchReset: .spring(response: 0.32, dampingFraction: 0.78),
                expandLiveActivity: .spring(response: 0.35, dampingFraction: 0.82),
                strokeVisibility: .smooth(duration: 0.26),
                notchVisibility: .smooth(duration: 0.42),
                contentTransition: .smooth(duration: 0.34)
            )

        case .balanced:
            return Self(
                contentUpdate: .spring(response: 0.4, dampingFraction: 0.8),
                contentHide: .spring(response: 0.5),
                contentShow: .spring(response: 0.4, dampingFraction: 0.8),
                stretchReset: .spring(response: 0.4, dampingFraction: 0.7),
                expandLiveActivity: .spring(response: 0.4, dampingFraction: 0.8),
                strokeVisibility: .spring(duration: 0.3),
                notchVisibility: .spring(duration: 0.6),
                contentTransition: .spring(duration: 0.5)
            )

        case .slow:
            return Self(
                contentUpdate: .spring(response: 0.48, dampingFraction: 0.82),
                contentHide: .spring(response: 0.6, dampingFraction: 0.92),
                contentShow: .spring(response: 0.48, dampingFraction: 0.82),
                stretchReset: .spring(response: 0.46, dampingFraction: 0.78),
                expandLiveActivity: .spring(response: 0.48, dampingFraction: 0.82),
                strokeVisibility: .smooth(duration: 0.36),
                notchVisibility: .smooth(duration: 0.62),
                contentTransition: .smooth(duration: 0.54)
            )

        case .relaxed:
            return Self(
                contentUpdate: .spring(response: 0.55, dampingFraction: 0.84),
                contentHide: .spring(response: 0.7, dampingFraction: 0.92),
                contentShow: .spring(response: 0.55, dampingFraction: 0.84),
                stretchReset: .spring(response: 0.52, dampingFraction: 0.8),
                expandLiveActivity: .spring(response: 0.55, dampingFraction: 0.84),
                strokeVisibility: .smooth(duration: 0.42),
                notchVisibility: .smooth(duration: 0.75),
                contentTransition: .smooth(duration: 0.6)
            )
        }
    }
}
