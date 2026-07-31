//
//  NotificationsPageNotchView.swift
//  DynamicNotch
//

import SwiftUI

/// Notifications page shared by the Home carousel and the ambient badge expanded view.
/// Renders the shared `NotificationCenterViewModel` as a two-level UX:
/// - Level 1 (list): header with "Clear" + scrollable rows.
/// - Level 2 (detail): full payload + Read / Done / Close buttons.
///
/// Tapping a row opens the detail without changing any state. Read/Done change state
/// and return to the list; Close returns without any change.
///
/// `isInCarousel`: when true (carousel via HomePageNotchView), a Spacer() in the outer
/// container already pushes content below the physical notch, so minimal top padding
/// suffices. When false (ambient badge expanded), the view fills the frame from y=0 and
/// must clear the physical notch (~37pt) with its own top padding.
struct NotificationsPageNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    @ObservedObject var notificationCenterViewModel: NotificationCenterViewModel
    var isInCarousel: Bool = false

    @State private var selectedItem: NotificationItem?

    // Top padding: badge starts at the notch ceiling and must clear the physical notch
    // hardware (~37pt); carousel's outer Spacer() already positions content lower.
    private var topPadding: CGFloat {
        if isDynamicIsland { return 8 }
        return isInCarousel ? 20 : 40
    }

    // Horizontal padding: carousel wrapper adds 30pt, so pages only need a few points.
    // Badge has no wrapper and needs clearance from the 24pt corner radius.
    private var horizontalPadding: CGFloat {
        if isDynamicIsland { return isInCarousel ? 6 : 14 }
        return isInCarousel ? 6 : 28
    }

    var body: some View {
        ZStack {
            if let item = selectedItem {
                NotificationDetailNotchView(
                    item: item,
                    viewModel: notificationCenterViewModel,
                    isInCarousel: isInCarousel,
                    onDismiss: { selectedItem = nil }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                listLevel
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedItem?.id)
    }

    private var listLevel: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Spacer(minLength: 8)

            if notificationCenterViewModel.items.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .padding(.top, topPadding)
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, isDynamicIsland ? 7 : 12)
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
                    Button {
                        selectedItem = item
                    } label: {
                        NotificationRowView(item: item)
                    }
                    .buttonStyle(.plain)
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
