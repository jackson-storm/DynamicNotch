//
//  NotchContentProtocol.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/25/26.
//

import SwiftUI

/// Core protocol defining the presentation content and behavior for items rendered in the Notch / Dynamic Island.
///
/// **Apple LiveActivity & Dynamic Island mapping:**
/// Conforming types act as content providers for Live Activities (ActivityKit) and Dynamic Island presentations (WidgetKit):
/// - **Compact Presentation** (`compactView`, `compactSize`, `compactCornerRadius`):
///   Corresponds to Apple's `compact` Dynamic Island presentation mode (`compactLeading` / `compactTrailing`).
/// - **Expanded Presentation** (`expandedView`, `expandedSize`, `expandedCornerRadius`):
///   Corresponds to Apple's `expanded` Dynamic Island presentation mode (`leading`, `trailing`, `center`, `bottom`).
/// - **Hardware Adaptation** (`DynamicIslandCustomizable`):
///   Adapts dimensions and corner radii between the physical bezel Notch and the floating pill Dynamic Island.
/// - **Activity Lifecycle & Scheduling** (`id`, `stackID`, `priority`, `isRestorable`):
///   Maps to Apple `ActivityAttributes` identification, stack replacement, priority ordering, and dismissal restoration.
/// - **Deep Linking & Interaction** (`expandsOnTap`, `widgetURL`):
///   Maps to Apple's Dynamic Island tap gestures, expand animations, and `widgetURL` / `Link` navigation into the host app.
protocol NotchContentProtocol: DynamicIslandCustomizable {
    // MARK: - Identification & Priority (Activity Attributes)

    /// Unique identifier for this activity instance (Apple: `Activity<Attributes>.id`).
    var id: String { get }

    /// Grouping identifier used for replacing or grouping activities in the same stack (e.g. downloads, timers).
    var stackID: String { get }

    /// Presentation priority score.
    /// Determines which Live Activity is displayed when multiple activities are concurrently active.
    /// Higher values take precedence in the Dynamic Island / Notch.
    var priority: Int { get }

    /// Accent border stroke color highlighting the activity state (e.g. green for charging, red for recording).
    var strokeColor: Color { get }

    // MARK: - Presentation Modes & Capabilities

    /// Indicates whether this activity supports an expanded presentation mode (Apple Dynamic Island: `.expanded`).
    var isExpandable: Bool { get }

    /// Indicates whether a user tap should transition the activity from compact to expanded presentation mode.
    var expandsOnTap: Bool { get }

    /// Indicates whether this activity can be restored if dismissed by the user (swipe away / dismiss).
    var isRestorable: Bool { get }

    /// Indicates whether smooth sizing and morphing animation effects should be applied when content resizes.
    var usesContentResizeEffect: Bool { get }

    /// Indicates whether this activity allows the interactive press scale effect on user click / touch down.
    var allowsPressScaleEffect: Bool { get }

    /// Indicates whether this activity allows the interactive press scale effect in compact (minimalistic) presentation mode.
    var allowsCompactPressScaleEffect: Bool { get }

    /// Deep-link or navigation action invoked when the user interacts with the activity to open the host application window.
    /// Equivalent to Apple's `widgetURL` / `Link` action in Dynamic Island.
    var widgetURL: (@MainActor () -> Void)? { get }

    /// Legacy alias for `widgetURL`.
    var windowLink: (@MainActor () -> Void)? { get }

    // MARK: - Apple Dynamic Island: Compact Presentation

    /// View builder for the compact presentation mode (Apple Dynamic Island: `compactLeading` / `compactTrailing`).
    @MainActor @ViewBuilder func compactView() -> AnyView

    /// Frame size for compact presentation mode (Apple Dynamic Island: `compact` mode size).
    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize

    /// Corner radii for compact presentation mode.
    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat)

    // MARK: - Apple Dynamic Island: Expanded Presentation

    /// View builder for the expanded presentation mode (Apple Dynamic Island: `expanded` layout).
    @MainActor @ViewBuilder func expandedView() -> AnyView

    /// Frame size for expanded presentation mode (Apple Dynamic Island: `expanded` mode size).
    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize

    /// Corner radii for expanded presentation mode.
    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat)
}

// MARK: - Default Implementations

extension NotchContentProtocol {
    var stackID: String { id }
    var priority: Int { NotchContentPriority.default }
    var strokeColor: Color { .white.opacity(0.2) }
    var isExpandable: Bool { false }
    var expandsOnTap: Bool { isExpandable }
    var isRestorable: Bool { true }
    var usesContentResizeEffect: Bool { true }
    var allowsPressScaleEffect: Bool { true }
    var allowsCompactPressScaleEffect: Bool { allowsPressScaleEffect }

    var widgetURL: (@MainActor () -> Void)? { windowLink }
    var windowLink: (@MainActor () -> Void)? { nil }

    // MARK: - View Builders

    @MainActor
    func expandedView() -> AnyView {
        compactView()
    }

    // MARK: - Geometry & Sizing

    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: baseRadius - 4, bottom: baseRadius)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        compactSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        compactCornerRadius(baseRadius: baseRadius)
    }

    // MARK: - Dynamic Island Customization Bridging

    func compactDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        dynamicIslandSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        compactSize(baseWidth: baseWidth, baseHeight: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let base = expandedSize(baseWidth: baseWidth, baseHeight: baseHeight)
        return CGSize(width: base.width + 40, height: base.height)
    }

    func compactDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        dynamicIslandCornerRadius(baseHeight: baseHeight)
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }
}
