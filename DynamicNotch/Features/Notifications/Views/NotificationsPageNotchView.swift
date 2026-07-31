//
//  NotificationsPageNotchView.swift
//  DynamicNotch
//

import SwiftUI

/// Read-only Notifications page for the Home carousel. Renders the shared
/// `NotificationCenterViewModel` list: a header (title + "Clear") and a scrollable
/// list of rows. Script-authored fields (`title`, `source`) are rendered with
/// `Text(verbatim:)` so a title like "50% done" is never treated as a localization key.
///
/// Slice 1 is read-only: tapping a row does nothing and there is no detail level yet
/// (Read/Done/Close arrive in a later slice). The row is factored into
/// `NotificationRowView` so the ambient badge can reuse it without a rewrite.
struct NotificationsPageNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    @ObservedObject var notificationCenterViewModel: NotificationCenterViewModel

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer()
            }
            .padding(.top, isDynamicIsland ? 8 : 4)
            .padding(.horizontal, isDynamicIsland ? 20 : 34)

            VStack(spacing: 0) {
                Spacer()

                if notificationCenterViewModel.items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .padding(.horizontal, isDynamicIsland ? 16 : 30)
            .padding(.bottom, isDynamicIsland ? 7 : 12)
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Text("Notifications")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    notificationCenterViewModel.clearAll()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                    Text("Clear")
                        .font(.system(size: 13))
                }
            }
            .buttonStyle(PressedButtonStyle(width: 74, height: 28))
            .disabled(notificationCenterViewModel.items.isEmpty)
            .opacity(notificationCenterViewModel.items.isEmpty ? 0.4 : 1)
        }
        .foregroundStyle(.white)
    }

    private var list: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 6) {
                ForEach(notificationCenterViewModel.items) { item in
                    NotificationRowView(item: item)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(maxHeight: 108)
        .mask {
            ScrollFadeMask(cornerRadius: 20, maskType: .verticalFade)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "bell.slash")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.gray.opacity(0.8))

            Text("No notifications")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)
    }
}

/// A single read-only notification row: severity bar, title, source · time, and an
/// unread dot. Script text uses `Text(verbatim:)`.
struct NotificationRowView: View {
    let item: NotificationItem

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(item.level.color)
                .frame(width: 3, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let source = item.source, !source.isEmpty {
                        Text(verbatim: source)
                            .lineLimit(1)

                        Text(verbatim: "·")
                    }

                    Text(item.receivedAt, format: .dateTime.hour().minute())
                }
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
            }

            Spacer(minLength: 4)

            if !item.read {
                Circle()
                    .fill(item.level.color)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }
}
