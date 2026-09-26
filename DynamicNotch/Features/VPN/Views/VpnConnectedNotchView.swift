//
//  VpnConnectedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI
import Combine
internal import AppKit

struct VpnConnectedNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @ObservedObject var vpnViewModel: VpnViewModel
    @ObservedObject var settings: ConnectivitySettingsStore
    
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeString: String = "00:00"
    
    private var resolvedVPNName: String {
        let trimmedText = vpnViewModel.vpnName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? "Secure Tunnel" : trimmedText
    }
    
    private var isShowingDetail: Bool {
        settings.isVPNDetailVisible
    }
    
    private func updateTimer() {
        guard let startDate = vpnViewModel.vpnConnectedAt else {
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
            if let bundleID = vpnViewModel.vpnBundleID, let nsImage = getAppIcon(for: bundleID) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isNotchlessScreen ? 20 : 30, height: isNotchlessScreen ? 20 : 30)
                    .cornerRadius(isNotchlessScreen ? 10 : 6)
                
            } else {
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.gradient)
            }
            Spacer()
            
            Text(verbatim: "Active")
                .foregroundStyle(.white)
        }
        .padding(.leading, isNotchlessScreen ? 6.scaled(by: scale) : 11.scaled(by: scale))
        .padding(.trailing, isNotchlessScreen ? 6.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private var detailedView: some View {
        VStack {
            Spacer()
            
            HStack {
                HStack(spacing: 14) {
                    if let bundleID = vpnViewModel.vpnBundleID, let nsImage = getAppIcon(for: bundleID) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                            .padding(.bottom, isNotchlessScreen ? 8 : 6)
                        
                    } else {
                        Image(systemName: "network.badge.shield.half.filled")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.bottom, 10)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: "Connected")
                            .lineLimit(1)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.4))
                            .fixedSize(horizontal: true, vertical: false)
                        
                        MarqueeText(
                            Binding.constant(resolvedVPNName),
                            font: .system(size: 15, weight: .regular),
                            nsFont: .body,
                            textColor: .white.opacity(0.8),
                            backgroundColor: .clear,
                            minDuration: 0.5,
                            frameWidth: 130
                        )
                    }
                }
                Spacer()
                
                Text(timeString)
                    .padding(.bottom, isNotchlessScreen ? 8 : 6)
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
        .padding(.horizontal, isNotchlessScreen ? 20 : 36)
        .padding(.bottom, isNotchlessScreen ? 9 : 10)
    }
    
    private func getAppIcon(for bundleID: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}

