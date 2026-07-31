import SwiftUI

/// Second level of the notifications UX: shows the full payload of a single item
/// (summary, title, source, time, icon) and offers Done / Read / Close.
///
/// The three actions are compact icon buttons docked at the header's top-right — the
/// conventional macOS spot — so the freed vertical space goes to the summary:
/// - Done (`checkmark`): removes the item from the list entirely, closes the detail.
/// - Read (`envelope.open`): marks the item read, keeps it in the list, closes the detail.
/// - Close (`xmark`): closes the detail without touching any state (item stays unread).
///
/// Icon-only buttons carry an `.accessibilityLabel` (VoiceOver) and `.help` (tooltip).
///
/// Script-authored fields (title, summary, source) use `Text(verbatim:)` so a title
/// like "50% done" is never interpreted as a localization key.
struct NotificationDetailNotchView: View {
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    let item: NotificationItem
    let viewModel: NotificationCenterViewModel
    var isInCarousel: Bool = false
    let onDismiss: () -> Void

    /// Ideal height of the summary text at the current width. Drives the scroll area's
    /// height so the notch shrink-wraps short summaries; capped by the active ceiling.
    @State private var summaryTextHeight: CGFloat = 0

    /// User-toggled via the footer chevron: when `true`, the summary ceiling jumps to
    /// `expandedSummaryHeight` so more (or all) of a long summary shows without scrolling.
    /// Per-notification `@State` — reset by `.id(item.id)` on the view so it never leaks
    /// an expanded pose onto the next, shorter notification.
    @State private var isExpanded = false

    /// Default ceiling for the summary area. Beyond this the summary scrolls instead of
    /// growing the notch — keeps the notch from becoming uselessly tall for long text.
    private let compactSummaryHeight: CGFloat = 340

    /// Ceiling once the user taps expand. Bounded (not uncapped) so a pathological summary
    /// can't grow the notch past the screen; tune on the physical notch.
    private let expandedSummaryHeight: CGFloat = 640

    /// Active summary ceiling for the current pose.
    private var maxSummaryHeight: CGFloat {
        isExpanded ? expandedSummaryHeight : compactSummaryHeight
    }

    /// The summary overflows the compact ceiling, so expanding reveals more — the only
    /// case where the footer chevron is worth showing.
    private var canExpand: Bool {
        summaryTextHeight > compactSummaryHeight
    }

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
            if canExpand {
                expandFooter
            }
        }
        .padding(.top, topPadding)
        .padding(.bottom, isDynamicIsland ? 12 : 16)
        .padding(.horizontal, horizontalPadding)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: DetailContentHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(DetailContentHeightKey.self) { height in
            viewModel.setDetailContentHeight(height)
        }
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

            Spacer(minLength: 6)

            actionButtons
        }
    }

    private var summaryArea: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(verbatim: item.summary)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: SummaryTextHeightKey.self, value: proxy.size.height)
                    }
                )
        }
        // Fit the text until it reaches the ceiling, then scroll. Before the first
        // measurement, size to the ceiling so the ScrollView lays out and measures.
        .frame(
            maxWidth: .infinity,
            maxHeight: summaryTextHeight <= 0 ? maxSummaryHeight : min(summaryTextHeight, maxSummaryHeight),
            alignment: .topLeading
        )
        .onPreferenceChange(SummaryTextHeightKey.self) { summaryTextHeight = $0 }
    }

    /// Bottom-right chevron that toggles the summary ceiling between compact and expanded.
    /// The tap is a plain state flip — no `withAnimation`: it jumps the frame once, yielding
    /// a single height delta and one clean notch resize spring (owned by the notch engine),
    /// instead of a per-frame storm of geometry refreshes fighting the notch's own spring.
    private var expandFooter: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            iconButton(
                isExpanded ? "chevron.up" : "chevron.down",
                tint: .white.opacity(0.75),
                background: .white.opacity(0.08),
                label: isExpanded ? "Show less" : "Show more"
            ) {
                isExpanded.toggle()
            }
        }
        .padding(.top, 6)
    }

    private var actionButtons: some View {
        HStack(spacing: 6) {
            iconButton(
                "checkmark",
                tint: .white.opacity(0.85),
                background: .white.opacity(0.1),
                label: "Done"
            ) {
                viewModel.markDone(id: item.id)
                onDismiss()
            }

            iconButton(
                "envelope.open",
                tint: .white,
                background: item.level.color.opacity(0.3),
                label: "Mark as read"
            ) {
                viewModel.markRead(id: item.id)
                onDismiss()
            }

            iconButton(
                "xmark",
                tint: .white.opacity(0.6),
                background: .white.opacity(0.06),
                label: "Close"
            ) {
                onDismiss()
            }
        }
    }

    /// Compact circular icon button used for the three header actions. Icon-only, so it
    /// pairs an `.accessibilityLabel` (VoiceOver) with a `.help` tooltip on hover.
    private func iconButton(
        _ systemName: String,
        tint: Color,
        background: Color,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(Circle().fill(background))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

/// Ideal height of the summary text (measured at the current width), used to size the
/// scroll area so short summaries don't leave empty space.
private struct SummaryTextHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Measured total height of the detail view, reported up so the notch fits its content.
private struct DetailContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
