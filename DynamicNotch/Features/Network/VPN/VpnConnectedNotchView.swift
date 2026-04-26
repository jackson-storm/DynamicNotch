//
//  VpnConnectedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct VpnConnectedNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var networkViewModel: NetworkViewModel
    @ObservedObject var settings: ConnectivitySettingsStore
    
    private var resolvedVPNName: String {
        let trimmedText = networkViewModel.vpnName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? "Secure Tunnel" : trimmedText
    }
    
    private var isShowingDetail: Bool {
        settings.isVPNDetailVisible
    }

    private func formattedElapsedTime(since startDate: Date, currentDate: Date) -> String {
        let totalSeconds = max(0, Int(currentDate.timeIntervalSince(startDate)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        HStack {
            leftContent
            Spacer()
            rightContent
        }
        .padding(.horizontal, 14.scaled(by: scale))
        .font(.system(size: 14))
    }

    @ViewBuilder
    private var leftContent: some View {
        if !isShowingDetail {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.gradient.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.accentColor.gradient)
                        .contentTransition(.symbolEffect(.replace))
                }

                Text(verbatim: "VPN")
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)))

        } else {
            MarqueeText(
                .constant(resolvedVPNName),
                font: .system(size: 14),
                nsFont: .body,
                textColor: .white.opacity(0.8),
                backgroundColor: .clear,
                minDuration: 0.5,
                frameWidth: 100
            )
            .lineLimit(1)
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .trailing)))
        }
    }

    @ViewBuilder
    private var rightContent: some View {
        if !isShowingDetail {
            Text(verbatim: "Connected")
                .transition(.blurAndFade.animation(.spring(duration: 0.4)))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)

        } else if settings.isVPNTimerVisible {
            HStack {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(networkViewModel.vpnConnectedAt.map { formattedElapsedTime(since: $0, currentDate: context.date) } ?? "--:--:--")
                        .monospacedDigit()
                        .foregroundStyle(.orange.gradient)
                }

                Image(systemName: "gauge.with.needle")
                    .font(Font.system(size: 18, weight: .semibold))
                    .foregroundStyle(.orange.gradient)
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .leading)))

        } else {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.orange)

                Text(verbatim: "Protected")
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .leading)))
        }
    }
}
