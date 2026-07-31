import SwiftUI

/// Second level of the notifications UX: shows the full payload of a single item
/// (summary, title, source, time, icon) and offers Read / Done / Close.
///
/// - Read: marks the item read, keeps it in the list, closes the detail.
/// - Done: removes the item from the list entirely, closes the detail.
/// - Close: closes the detail without touching any state (item stays unread).
///
/// Script-authored fields (title, summary, source) use `Text(verbatim:)` so a title
/// like "50% done" is never interpreted as a localization key.
struct NotificationDetailNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    let item: NotificationItem
    let viewModel: NotificationCenterViewModel
    var isInCarousel: Bool = false
    let onDismiss: () -> Void

    private var topPadding: CGFloat {
        if isDynamicIsland { return 8 }
        return isInCarousel ? 20 : 40
    }

    private var horizontalPadding: CGFloat {
        if isDynamicIsland { return isInCarousel ? 6 : 14 }
        return isInCarousel ? 6 : 28
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
                .background(.white.opacity(0.12))
                .padding(.vertical, 8)
            summaryArea
            Spacer(minLength: 4)
            actionButtons
        }
        .padding(.top, topPadding)
        .padding(.bottom, isDynamicIsland ? 8 : 10)
        .padding(.horizontal, horizontalPadding)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.effectiveIconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(item.level.color)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

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
        }
    }

    private var summaryArea: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(verbatim: item.summary)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxHeight: 52)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.markDone(id: item.id)
                onDismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(height: 30, backgroundColor: .white.opacity(0.12)))

            Button {
                viewModel.markRead(id: item.id)
                onDismiss()
            } label: {
                Text("Read")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(height: 30, backgroundColor: item.level.color.opacity(0.25)))

            Button {
                onDismiss()
            } label: {
                Text("Close")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(PrimaryButtonStyle(height: 30, backgroundColor: .white.opacity(0.06)))
        }
    }
}
