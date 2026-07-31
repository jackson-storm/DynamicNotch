//
//  NotificationsBadgeNotchView.swift
//  DynamicNotch
//

import SwiftUI

/// Compact ambient badge shown on the resting notch: a bell on the far left and the
/// animated unread counter on the far right, so the pair flanks the physical notch rather
/// than clustering in the middle. Both are tinted by the highest unread severity
/// (error > warning > success > info). It observes the shared `NotificationCenterViewModel`
/// so the count and tint track mutations without the coordinator re-sending the activity.
struct NotificationsBadgeNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    @ObservedObject var notificationCenterViewModel: NotificationCenterViewModel

    private var tint: Color {
        notificationCenterViewModel.highestUnreadLevel?.color ?? .white
    }

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "bell.fill")
                .font(.system(size: isDynamicIsland ? 14 : 16, weight: .semibold))
                .foregroundStyle(tint)

            Spacer(minLength: 6)

            AnimatedLevelText(
                level: notificationCenterViewModel.unreadCount,
                fontSize: 16,
                color: tint
            )
        }
        .padding(.horizontal, isDynamicIsland ? 8.scaled(by: scale) : 14.scaled(by: scale))
    }
}
