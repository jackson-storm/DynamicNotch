//
//  NotchState.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/18/26.
//

import Foundation

/// State events driving the Notch and Dynamic Island lifecycle.
///
/// Directly maps to Apple's **ActivityKit & Dynamic Island Lifecycle**:
/// - `showLiveActivity`: Starts or updates an ongoing Live Activity (Apple: `Activity.request` / `activity.update`).
/// - `hideLiveActivity`: Ends / terminates an ongoing Live Activity (Apple: `activity.end`).
/// - `dismissLiveActivity`: Dismisses the Live Activity from the Dynamic Island into the background (can be restored).
/// - `showTemporaryNotification`: Posts a transient alert / HUD notification (e.g. Volume/Brightness, Lock, AirPods) that temporarily preempts Live Activities.
/// - `hide`: Clears and dismisses all active presentations.
enum NotchState {
    /// Start or update a persistent Live Activity with new content.
    case showLiveActivity(NotchContentProtocol)

    /// End and remove a Live Activity by its unique identifier.
    case hideLiveActivity(id: String)

    /// Dismiss a Live Activity from the Dynamic Island display while keeping it in the restorable stack.
    case dismissLiveActivity(id: String)

    /// Expand a chosen ongoing activity without removing the other activities.
    case selectLiveActivity(id: String)

    /// Show a transient alert / HUD notification for a specified duration, temporarily preempting any active Live Activity.
    case showTemporaryNotification(NotchContentProtocol, duration: TimeInterval)

    /// Dismiss and hide all active content from the Notch / Dynamic Island.
    case hide
}
