//
//  VpnDisconnectedNotchView.swift
//  DynamicNotch
//
//  Created by Antigravity on 7/4/26.
//

import SwiftUI
import Combine
internal import AppKit

struct VpnDisconnectedNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var vpnViewModel: VpnViewModel
    @ObservedObject var settings: ConnectivitySettingsStore
    
    private var resolvedVPNName: String {
        let name = vpnViewModel.vpnName.isEmpty ? vpnViewModel.lastVpnName : vpnViewModel.vpnName
        let trimmedText = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? "Secure Tunnel" : trimmedText
    }
    
    private var resolvedBundleID: String? {
        vpnViewModel.vpnBundleID ?? vpnViewModel.lastVpnBundleID
    }
    
    private var isShowingDetail: Bool {
        settings.isVPNDetailVisible
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
            if let bundleID = resolvedBundleID, let nsImage = getAppIcon(for: bundleID) {
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
            
            Text(verbatim: "Inactive")
                .foregroundStyle(.red)
        }
        .padding(.leading, isDynamicIsland ? 6.scaled(by: scale) : 11.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 6.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private var detailedView: some View {
        VStack {
            Spacer()
            
            HStack {
                HStack(spacing: 12) {
                    if let bundleID = resolvedBundleID, let nsImage = getAppIcon(for: bundleID) {
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
                        Text(verbatim: "Disconnected")
                            .lineLimit(1)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
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
                
                Text("--:--")
                    .padding(.bottom, isDynamicIsland ? 8 : 6)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.gray)
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
