//
//  VpnConnectView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 2/21/26.
//

import SwiftUI

struct VpnConnectedNotchContent : NotchContentProtocol {
    let id = "vpn.connected"
    let networkViewModel: NetworkViewModel
    
    var offsetXTransition: CGFloat { -90 }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let width = networkViewModel.isShowingVPNDetail ? 210 : 170
        return .init(width: baseWidth + CGFloat(width), height: baseHeight)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(VpnConnectedNotchView(networkViewModel: networkViewModel))
    }
}

private struct VpnConnectedNotchView: View {
    @Environment(\.notchScale) var scale
    @ObservedObject var networkViewModel: NetworkViewModel
    
    private var resolvedVPNName: String {
        let trimmedText = networkViewModel.vpnName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? "Secure Tunnel" : trimmedText
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
        .onAppear {
            networkViewModel.isShowingVPNDetail = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(duration: 0.4)) {
                    networkViewModel.isShowingVPNDetail = true
                }
            }
        }
        .onDisappear {
            networkViewModel.isShowingVPNDetail = false
        }
    }
    
    @ViewBuilder
    private var leftContent: some View {
        if !networkViewModel.isShowingVPNDetail {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.blue)
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text("VPN")
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)))
            
        } else {
            if networkViewModel.isShowingVPNDetail {
                MarqueeText(
                    .constant(resolvedVPNName),
                    font: .system(size: 14),
                    nsFont: .body,
                    textColor: .white.opacity(0.8),
                    backgroundColor: .clear,
                    minDuration: 0.5,
                    frameWidth: 110
                )
                .lineLimit(1)
                .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .trailing)))
            }
        }
    }
    
    @ViewBuilder
    private var rightContent: some View {
        if !networkViewModel.isShowingVPNDetail {
            Text("Connected")
                .transition(.blurAndFade.animation(.spring(duration: 0.4)))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
            
        } else {
            HStack {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(networkViewModel.vpnConnectedAt.map {formattedElapsedTime(since: $0, currentDate: context.date)} ?? "--:--:--")
                        .monospacedDigit()
                        .foregroundStyle(.orange.gradient)
                }
                
                Image(systemName: "gauge.with.needle")
                    .font(Font.system(size: 18))
                    .foregroundStyle(.orange)
            }
            .transition(.blurAndFade.animation(.spring(duration: 0.4)).combined(with: .push(from: .leading)))
        }
    }
}
