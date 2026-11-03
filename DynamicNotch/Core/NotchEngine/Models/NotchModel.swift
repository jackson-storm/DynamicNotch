//
//  NotchModel.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/18/26.
//

import Foundation
import SwiftUI

/// Core presentation model representing the visual state of the Notch and Dynamic Island.
///
/// **Apple LiveActivity & Dynamic Island architecture:**
/// This model mirrors Apple's presentation system for Dynamic Island and Live Activities (ActivityKit / WidgetKit):
/// - **Ongoing Live Activities** (`liveActivityContent` / `activityContent`):
///   Long-running persistent activities (e.g. Media Playback, Active Timer, Downloads, Battery status).
/// - **Transient Alerts / Notifications** (`alertContent` / `temporaryNotificationContent`):
///   Short-lived banner/HUD alerts (e.g. Volume/Brightness changes, AirPods connect, Lock screen status)
///   that temporarily preempt ongoing Live Activities.
/// - **Presentation Modes** (`isExpanded`):
///   Transitions between **Compact** (pill/notch resting state) and **Expanded** (detailed interactive sheet).
/// - **Hardware Adaptation** (`isDynamicIsland`):
///   Adapts rendering and corner radii between the physical bezel Notch and the floating Dynamic Island pill.
struct NotchModel: Equatable {
    // MARK: - Active Content (Apple LiveActivity & Alerts)

    /// Currently active persistent Live Activity (Apple: ongoing `Activity<Attributes>` content).
    var liveActivityContent: NotchContentProtocol? = nil

    /// Currently active transient alert or HUD notification (Apple: transient Dynamic Island alert/banner).
    /// When present, this content takes visual precedence over the ongoing Live Activity.
    var alertContent: NotchContentProtocol? = nil

    /// Current presentation mode: `true` for **Expanded** mode (Apple: `.expanded`), `false` for **Compact** mode (Apple: `.compact`).
    var isExpanded: Bool = false

    /// Currently displayed content: returns transient alert if active, otherwise falls back to ongoing Live Activity.
    var content: NotchContentProtocol? { alertContent ?? liveActivityContent }

    // MARK: - Base Geometry & Hardware Configuration

    /// Base width of the physical notch or Dynamic Island pill.
    var baseWidth: CGFloat = 190

    /// Base height of the physical notch or Dynamic Island pill.
    var baseHeight: CGFloat = 38

    /// Interactive scale multiplier for gesture stretch and bounce animations.
    var scale: CGFloat = 1.0

    /// Hardware style flag: `true` for floating Dynamic Island pill (screens without physical notch), `false` for hardware bezel notch.
    var isDynamicIsland: Bool = false

    // MARK: - Presentation State & Identification

    /// Indicates whether the Notch/Island is actively presenting the expanded mode of an expandable activity (Apple: `isExpanded`).
    var isPresentingExpanded: Bool {
        isExpanded && (content?.isExpandable ?? false)
    }

    /// Unique presentation identifier distinguishing between compact and expanded states for smooth SwiftUI transition animations.
    var presentationID: String? {
        guard let content else { return nil }

        if isPresentingExpanded {
            return "\(content.id).expanded"
        }

        return content.id
    }

    /// Calculated frame size based on presentation mode (`compact` vs `expanded`) and display style (Notch vs Dynamic Island).
    var size: CGSize {
        guard let content else { return .init(width: baseWidth, height: baseHeight) }

        if isPresentingExpanded {
            if isDynamicIsland {
                return content.expandedDynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
            }
            return content.expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
        }

        if isDynamicIsland {
            return content.compactDynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
        }
        return content.compactSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    /// Corner radii (top and bottom curves) for current presentation mode and hardware style.
    var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        let baseRadius = baseHeight / 3
        guard let content else { return (top: baseRadius - 4, bottom: baseRadius) }

        if isPresentingExpanded {
            return content.expandedCornerRadius(baseRadius: baseRadius)
        }

        return content.compactCornerRadius(baseRadius: baseRadius)
    }

    /// Outline stroke color matching the current activity theme or status.
    var strokeColor: Color { content?.strokeColor ?? .clear }

    /// Token updated on state mutations to trigger SwiftUI view updates.
    var updateToken = UUID()

    // MARK: - Apple LiveActivity Aliases & Compatibility

    /// Alias for `alertContent` (legacy name: `temporaryNotificationContent`).
    var temporaryNotificationContent: NotchContentProtocol? {
        get { alertContent }
        set { alertContent = newValue }
    }

    /// Alias for `liveActivityContent` (Apple: `activityContent`).
    var activityContent: NotchContentProtocol? {
        get { liveActivityContent }
        set { liveActivityContent = newValue }
    }

    /// Alias for `isExpanded` (legacy name: `isLiveActivityExpanded`).
    var isLiveActivityExpanded: Bool {
        get { isExpanded }
        set { isExpanded = newValue }
    }

    /// Alias for `isPresentingExpanded` (legacy name: `isPresentingExpandedLiveActivity`).
    var isPresentingExpandedLiveActivity: Bool {
        isPresentingExpanded
    }

    /// Apple LiveActivity equivalent: Active Live Activity.
    var activeLiveActivity: NotchContentProtocol? {
        liveActivityContent
    }

    /// Apple LiveActivity equivalent: Transient alert / HUD notification.
    var transientAlert: NotchContentProtocol? {
        alertContent
    }

    /// Apple LiveActivity equivalent: The active visual presentation content.
    var activePresentation: NotchContentProtocol? {
        content
    }

    // MARK: - Initializers

    init() {}

    init(
        liveActivityContent: NotchContentProtocol? = nil,
        alertContent: NotchContentProtocol? = nil,
        isExpanded: Bool = false,
        baseWidth: CGFloat = 190,
        baseHeight: CGFloat = 38,
        scale: CGFloat = 1.0,
        isDynamicIsland: Bool = false
    ) {
        self.liveActivityContent = liveActivityContent
        self.alertContent = alertContent
        self.isExpanded = isExpanded
        self.baseWidth = baseWidth
        self.baseHeight = baseHeight
        self.scale = scale
        self.isDynamicIsland = isDynamicIsland
    }

    init(
        liveActivityContent: NotchContentProtocol?,
        temporaryNotificationContent: NotchContentProtocol?,
        isLiveActivityExpanded: Bool,
        baseWidth: CGFloat = 190,
        baseHeight: CGFloat = 38,
        scale: CGFloat = 1.0,
        isDynamicIsland: Bool = false
    ) {
        self.liveActivityContent = liveActivityContent
        self.alertContent = temporaryNotificationContent
        self.isExpanded = isLiveActivityExpanded
        self.baseWidth = baseWidth
        self.baseHeight = baseHeight
        self.scale = scale
        self.isDynamicIsland = isDynamicIsland
    }

    // MARK: - Equatable

    static func == (lhs: NotchModel, rhs: NotchModel) -> Bool {
        lhs.content?.id == rhs.content?.id &&
        lhs.isExpanded == rhs.isExpanded &&
        lhs.baseWidth == rhs.baseWidth &&
        lhs.baseHeight == rhs.baseHeight &&
        lhs.scale == rhs.scale &&
        lhs.isDynamicIsland == rhs.isDynamicIsland &&
        lhs.updateToken == rhs.updateToken
    }
}

