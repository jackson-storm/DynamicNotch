//
//  NotchAnimations.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/29/26.
//

import SwiftUI

struct NotchAnimations {
    // MARK: - Notifications & Content Lifecycle
    /// Animation used when collapsing/hiding notch content.
    let hideContent: Animation
    /// Animation used when expanding/showing notch content from collapsed state.
    let showContent: Animation

    // MARK: - Live Activity
    /// Geometry animation when expanding Live Activity from compact to expanded state.
    let expandLiveActivity: Animation
    /// Geometry animation when collapsing Live Activity back to compact or closed state.
    let collapseLiveActivity: Animation

    // MARK: - Gestures & Interactions
    /// Animation used when updating notch content/geometry without full collapse.
    let updateContent: Animation
    /// Spring animation returning the notch to resting state after swipe/drag stretch.
    let stretchReset: Animation
    /// Squeeze-and-bounce spring animation when notch loses focus or is dismissed.
    let focusDismissBounce: Animation

    // MARK: - Shell Visibility & Stroke
    /// Animation for showing/hiding the decorative border stroke.
    let strokeVisibility: Animation
    /// Animation for overall notch window visibility toggle.
    let notchVisibility: Animation

    // MARK: - Delays
    /// Delay between hiding previous item and displaying next item.
    let transitionDelay: TimeInterval
    /// Minimum pacing delay when processing queue items.
    let queuePacingDelay: TimeInterval

    static let animations: Self = {
        // Dynamic Island physics (System Aperture / Apple SpringBoard curves)
        // Expansion: snappy with slight elastic momentum
        let expandResponse: Double = 0.46
        let expandDamping: Double = 0.76

        // Collapse / Dismiss: slightly faster and more damped
        let collapseResponse: Double = 0.46
        let collapseDamping: Double = 0.86

        // Quick content updates & notifications
        let contentResponse: Double = 0.48
        let contentDamping: Double = 0.86

        // Rubber-band gesture snap-back
        let gestureResponse: Double = 0.42
        let gestureDamping: Double = 0.76
        
        let blendDuration: Double = 0.3
        let transitionDelay: Double = 0.29
        let queuePacingDelay: Double = 0.3
        
        return Self(
            hideContent: .spring(response: collapseResponse, dampingFraction: collapseDamping, blendDuration: blendDuration),
            showContent: .spring(response: contentResponse, dampingFraction: contentDamping, blendDuration: blendDuration),
            
            expandLiveActivity: .spring(response: expandResponse, dampingFraction: expandDamping, blendDuration: blendDuration),
            collapseLiveActivity: .spring(response: collapseResponse, dampingFraction: collapseDamping, blendDuration: blendDuration),
            
            updateContent: .spring(response: contentResponse, dampingFraction: contentDamping),
            stretchReset: .spring(response: gestureResponse, dampingFraction: gestureDamping),
            focusDismissBounce: .spring(response: gestureResponse, dampingFraction: gestureDamping),
            strokeVisibility: .spring(response: contentResponse, dampingFraction: contentDamping),
            notchVisibility: .spring(response: contentResponse, dampingFraction: contentDamping),
            
            transitionDelay: transitionDelay,
            queuePacingDelay: queuePacingDelay
        )
    }()
}
