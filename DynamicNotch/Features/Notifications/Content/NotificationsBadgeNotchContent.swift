//
//  NotificationsBadgeNotchContent.swift
//  DynamicNotch
//

import SwiftUI

/// Ambient badge live activity. Compact view = bell + unread counter; expanded (on tap)
/// = the shared notifications list (the slice-1 page view). Show/hide is driven by the
/// coordinator from `NotificationCenterViewModel.isBadgeVisible`; this type only describes
/// the content and its geometry.
struct NotificationsBadgeNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Notifications.badge.id
    let notificationCenterViewModel: NotificationCenterViewModel

    var priority: Int { NotchContentRegistry.Notifications.badge.priority }
    var isExpandable: Bool { true }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 52, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 170, height: baseHeight + 130)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 38)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 40, height: baseHeight)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 200, height: baseHeight + 130)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            NotificationsBadgeNotchView(
                notificationCenterViewModel: notificationCenterViewModel
            )
        )
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            NotificationsPageNotchView(
                notificationCenterViewModel: notificationCenterViewModel
            )
        )
    }
}
