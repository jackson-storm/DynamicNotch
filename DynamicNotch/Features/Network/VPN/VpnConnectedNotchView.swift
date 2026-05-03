//
//  VpnConnectedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI
import Combine

struct VpnConnectedNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var networkViewModel: NetworkViewModel
    @ObservedObject var settings: ConnectivitySettingsStore
    
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeString: String = "00:00"
    
    private var resolvedVPNName: String {
        let trimmedText = networkViewModel.vpnName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? "Secure Tunnel" : trimmedText
    }
    
    private var isShowingDetail: Bool {
        settings.isVPNDetailVisible
    }
    
    private func updateTimer() {
        guard let startDate = networkViewModel.vpnConnectedAt else {
            timeString = "00:00"
            return
        }
        
        let elapsed = Date().timeIntervalSince(startDate)
        timeString = elapsed.formattedDuration
    }
    
    var body: some View {
        HStack {
            if isShowingDetail {
                detailedView
            } else {
                compactView
            }
        }
        .font(.system(size: 14))
    }
    
    @ViewBuilder
    private var compactView: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.gradient)
                    .frame(width: 24, height: 24)
                
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.gradient)
            }
            Spacer()
            
            Text(verbatim: "Active")
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 14.scaled(by: scale))
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private var detailedView: some View {
        VStack {
            Spacer()
            
            HStack {
                HStack(spacing: 16) {
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.bottom, 10)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: "Connected")
                            .lineLimit(1)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.4))
                        
                        MarqueeText(
                            Binding.constant(resolvedVPNName),
                            font: .system(size: 15, weight: .regular),
                            nsFont: .body,
                            textColor: .white.opacity(0.8),
                            backgroundColor: .clear,
                            minDuration: 0.5,
                            frameWidth: 130.scaled(by: scale)
                        )
                    }
                }
                Spacer()
                
                Text(timeString)
                    .padding(.bottom, 10)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.orange)
                    .contentTransition(.numericText())
                    .onReceive(timer) { _ in
                        updateTimer()
                    }
                    .onAppear {
                        updateTimer()
                    }
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 10)
    }
}

