internal import AppKit
import SwiftUI

struct ClipboardHistoryNotchView: View {
    @ObservedObject var viewModel: ClipboardHistoryViewModel

    let topClearance: CGFloat
    let appliesOuterPadding: Bool
    let onItemRestored: (() -> Void)?

    init(
        viewModel: ClipboardHistoryViewModel,
        topClearance: CGFloat,
        appliesOuterPadding: Bool,
        onItemRestored: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.topClearance = topClearance
        self.appliesOuterPadding = appliesOuterPadding
        self.onItemRestored = onItemRestored
    }

    var body: some View {
        VStack(spacing: 10) {
            if topClearance > 0 {
                Color.clear
                    .frame(height: topClearance)
            }

            header

            if viewModel.items.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .padding(.horizontal, appliesOuterPadding ? 36 : 0)
        .padding(.bottom, appliesOuterPadding ? 28 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ClipboardDesign.accent)

                Text(verbatim: "Recent clips")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(verbatim: "\(viewModel.items.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ClipboardDesign.accent)
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(ClipboardDesign.accent.opacity(0.14), in: Capsule())
                    .accessibilityLabel("\(viewModel.items.count) recent items")
            }

            Spacer(minLength: 8)

            if !viewModel.items.isEmpty {
                Menu {
                    Button(role: .destructive) {
                        viewModel.clearHistory()
                    } label: {
                        Label("Clear history", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Clipboard history actions")
                .accessibilityLabel("Clipboard history actions")
            }
        }
        .frame(height: 30)
    }

    private var historyList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 6) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    ClipboardHistoryRow(
                        item: item,
                        recencyIndex: index + 1,
                        isCurrent: viewModel.currentItemID == item.id,
                        restoreFailure: viewModel.restoreFailure?.itemID == item.id ? viewModel.restoreFailure : nil,
                        onRestore: {
                            if viewModel.restore(item) {
                                onItemRestored?()
                            }
                        },
                        onRemove: { viewModel.remove(item) }
                    )
                }
            }
            .padding(.bottom, 2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 7) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(ClipboardDesign.accent.opacity(0.85))

            Text(verbatim: "No recent clips")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))

            Text(verbatim: "Copy text, a link, an image, or files to see them here.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.42))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(verbatim: "Stored only in memory")
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(ClipboardDesign.accent.opacity(0.62))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 8)
    }
}

private struct ClipboardHistoryRow: View {
    let item: ClipboardHistoryItem
    let recencyIndex: Int
    let isCurrent: Bool
    let restoreFailure: ClipboardRestoreFailure?
    let onRestore: () -> Void
    let onRemove: () -> Void

    @State private var isHovering = false
    @State private var imagePreview: NSImage?

    var body: some View {
        HStack(spacing: 7) {
            Button(action: onRestore) {
                HStack(spacing: 9) {
                    Text(verbatim: String(format: "%02d", recencyIndex))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(isCurrent ? ClipboardDesign.accent : .white.opacity(0.3))
                        .frame(width: 18, alignment: .leading)

                    payloadPreview

                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: item.payload.preview)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.84))
                            .lineLimit(1)
                            .truncationMode(.tail)

                        rowMetadata
                    }

                    Spacer(minLength: 4)

                    Image(systemName: statusSystemImage)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusColor)
                        .frame(width: 20)
                        .contentTransition(.symbolEffect(.replace))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy \(item.payload.preview) to the clipboard")

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(isHovering ? 0.58 : 0.26))
                    .frame(width: 26, height: 30)
            }
            .buttonStyle(.plain)
            .help("Remove from history")
            .accessibilityLabel("Remove \(item.payload.preview) from history")
        }
        .padding(.leading, 9)
        .padding(.trailing, 7)
        .frame(height: 45)
        .background(
            rowSurface,
            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(ClipboardDesign.accent.opacity(0.16), lineWidth: 1)
            }
        }
        .overlay(alignment: .leading) {
            if isCurrent {
                Capsule()
                    .fill(ClipboardDesign.accent)
                    .frame(width: 2, height: 22)
                    .padding(.leading, 1)
            }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) {
                isHovering = hovering
            }
        }
        .task(id: item.id) {
            guard imagePreview == nil,
                  case .image(let data) = item.payload else { return }
            imagePreview = NSImage(data: data)
        }
    }

    @ViewBuilder
    private var rowMetadata: some View {
        if let restoreFailure {
            Text(verbatim: restoreFailure.message)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(ClipboardDesign.warning)
                .lineLimit(1)
        } else {
            HStack(spacing: 4) {
                if isCurrent {
                    Text(verbatim: "Current")
                        .foregroundStyle(ClipboardDesign.accent.opacity(0.82))
                    Text(verbatim: "•")
                }

                Text(verbatim: item.payload.kind.title)

                if let source = item.sourceApplicationName, !source.isEmpty {
                    Text(verbatim: "•")
                    Text(verbatim: source)
                        .lineLimit(1)
                }

                Text(verbatim: "•")
                Text(item.capturedAt, style: .relative)
            }
            .font(.system(size: 9.5, weight: .medium))
            .foregroundStyle(.white.opacity(0.38))
            .lineLimit(1)
        }
    }

    private var statusSystemImage: String {
        if restoreFailure != nil { return "exclamationmark.triangle.fill" }
        return isCurrent ? "checkmark" : "arrow.up.doc"
    }

    private var statusColor: Color {
        if restoreFailure != nil { return ClipboardDesign.warning }
        if isCurrent { return ClipboardDesign.accent }
        return .white.opacity(isHovering ? 0.7 : 0.35)
    }

    private var rowSurface: Color {
        if isCurrent { return ClipboardDesign.currentSurface }
        return isHovering ? ClipboardDesign.hoverSurface : ClipboardDesign.elevatedSurface
    }

    @ViewBuilder
    private var payloadPreview: some View {
        switch item.payload {
        case .image:
            if let imagePreview {
                Image(nsImage: imagePreview)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                kindIcon
            }

        default:
            kindIcon
        }
    }

    private var kindIcon: some View {
        Image(systemName: item.payload.kind.systemImage)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ClipboardDesign.accent)
            .frame(width: 28, height: 28)
            .background(ClipboardDesign.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

struct ClipboardAccessButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var viewModel: ClipboardHistoryViewModel
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            if reduceMotion {
                isPresented.toggle()
            } else {
                withAnimation(.easeOut(duration: 0.16)) {
                    isPresented.toggle()
                }
            }
        } label: {
            Image(systemName: isPresented ? "xmark" : "doc.on.clipboard")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isPresented ? Color.black.opacity(0.72) : Color.white.opacity(0.72))
                .frame(width: 32, height: 32)
                .background(isPresented ? ClipboardDesign.accent : Color.white.opacity(0.08), in: Circle())
                .overlay(alignment: .topTrailing) {
                    if !isPresented && !viewModel.items.isEmpty {
                        Text(verbatim: "\(min(viewModel.items.count, 99))")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.black.opacity(0.72))
                            .frame(minWidth: 14, minHeight: 14)
                            .background(ClipboardDesign.accent, in: Capsule())
                            .offset(x: 3, y: -3)
                    }
                }
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .help(helpText)
        .accessibilityLabel(helpText)
    }

    private var helpText: String {
        if isPresented { return "Close clipboard history" }
        if viewModel.items.isEmpty { return "Open clipboard history, no recent items" }
        return "Open clipboard history, \(viewModel.items.count) recent items"
    }
}
