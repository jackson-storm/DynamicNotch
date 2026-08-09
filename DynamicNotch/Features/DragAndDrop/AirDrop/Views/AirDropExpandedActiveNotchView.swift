//
//  AirDropExpandedActiveNotchView.swift
//  DynamicNotch
//

import SwiftUI
internal import AppKit

struct AirDropExpandedActiveNotchView: View {
    @ObservedObject var airDropViewModel: AirDropNotchViewModel
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    var body: some View {
        VStack {
            Spacer()
            contentCard
        }
        .padding(.horizontal, isDynamicIsland ? 10 : 36)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var contentCard: some View {
        if let transfer = airDropViewModel.activeTransfer {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 55)
                
                HStack {
                    fileIcon(for: transfer)
                        .frame(width: 36, height: 36)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        MarqueeText(
                            .constant(transfer.fileName),
                            font: .system(size: 14, weight: .medium),
                            nsFont: .body,
                            textColor: .white,
                            backgroundColor: .clear,
                            minDuration: 2.0,
                            frameWidth: 110.scaled(by: scale)
                        )
                        
                        if transfer.urls.count > 1 {
                            Text("\(transfer.urls.count) files")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.7))
                        } else if let url = transfer.fileURL {
                            Text(url.pathExtension.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    Spacer()
                    transferBadge(for: transfer)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: transfer.status)
                }
                .padding(10)
            }
        }
    }

    @ViewBuilder
    private func fileIcon(for transfer: AirDropTransferInfo) -> some View {
        if let url = transfer.fileURL {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "doc.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private func transferBadge(for transfer: AirDropTransferInfo) -> some View {
        switch transfer.status {
        case .transferring:
            AirDropTransferProgressRingView(
                progress: transfer.progress,
                size: 30,
                lineWidth: 3.5,
                ringColor: .blue,
                stopSquareSize: 10
            )
            .transition(.scale(scale: 0.75).combined(with: .opacity))

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.green)
                .transition(.scale(scale: 1.25).combined(with: .opacity))

        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.red)
                .transition(.scale(scale: 1.25).combined(with: .opacity))
        }
    }

    private var statusLocalizedStringKey: LocalizedStringKey {
        guard let transfer = airDropViewModel.activeTransfer else { return "Ready" }
        switch transfer.status {
        case .transferring:
            return "Sending items..."
        case .completed:
            return "Transfer complete"
        case .failed(let message):
            return message.isEmpty ? "Transfer failed" : LocalizedStringKey(message)
        }
    }

    private var statusColor: Color {
        guard let transfer = airDropViewModel.activeTransfer else { return .secondary }
        switch transfer.status {
        case .transferring:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}
