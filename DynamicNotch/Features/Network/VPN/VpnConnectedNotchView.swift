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
    @Environment(\.isDynamicIsland) private var isDynamicIsland
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
            if let bundleID = networkViewModel.vpnBundleID, let nsImage = getAppIcon(for: bundleID) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isDynamicIsland ? 20 : 30, height: isDynamicIsland ? 20 : 30)
                    .cornerRadius(isDynamicIsland ? 10 : 6)
                
            } else {
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.gradient)
            }
            Spacer()
            
            Text(verbatim: "Active")
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.leading, isDynamicIsland ? 6.scaled(by: scale) : 11.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 8.scaled(by: scale) : 16.scaled(by: scale))
        .padding(.vertical, isDynamicIsland ? 0 : 10)
    }
    
    @ViewBuilder
    private var detailedView: some View {
        VStack {
            Spacer()
            
            HStack {
                HStack(spacing: 16) {
                    if let bundleID = networkViewModel.vpnBundleID, let nsImage = getAppIcon(for: bundleID) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                            .padding(.bottom, isDynamicIsland ? 8 : 6)
                        
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
                    .padding(.bottom, isDynamicIsland ? 8 : 6)
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
        .padding(.horizontal, isDynamicIsland ? 20 : 36)
        .padding(.vertical, 10)
    }
    
    private func getAppIcon(for bundleID: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}

