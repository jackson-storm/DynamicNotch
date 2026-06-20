//
//  VpnSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/19/26.
//

import SwiftUI
internal import AppKit

struct VpnSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    @StateObject private var vpnViewModel = VpnPageViewModel()
    
    var body: some View {
        SettingsPageScrollView {
            preferredVpnCard
        }
        .onAppear {
            vpnViewModel.startMonitoring()
        }
        .onDisappear {
            vpnViewModel.stopMonitoring()
        }
    }
    
    @ViewBuilder
    private var preferredVpnCard: some View {
        SettingsCard(title: "Preferred VPN") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select the VPN connection that you want to control from the notch.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if vpnViewModel.vpns.isEmpty {
                    if vpnViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Text("No VPN configurations found on this Mac. Please add a VPN connection in System Settings -> VPN first.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(vpnViewModel.vpns) { vpn in
                            HStack(spacing: 12) {
                                // Icon
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    if let bundleID = vpn.bundleID, let nsImage = getAppIcon(for: bundleID) {
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20, height: 20)
                                            .cornerRadius(4)
                                    } else {
                                        Image(systemName: "shield")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Color.gray)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(vpn.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text(vpn.type)
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // Selection Radio
                                if connectivitySettings.selectedVPNID == vpn.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 18))
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(connectivitySettings.selectedVPNID == vpn.id ? Color.blue.opacity(0.1) : Color.white.opacity(0.02))
                            )
                            .onTapGesture {
                                connectivitySettings.selectedVPNID = vpn.id
                            }
                            
                            if vpn.id != vpnViewModel.vpns.last?.id {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getAppIcon(for bundleID: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
