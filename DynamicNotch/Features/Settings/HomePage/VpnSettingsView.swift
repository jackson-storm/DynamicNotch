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
        .onChange(of: vpnViewModel.vpns) { _, newVpns in
            if newVpns.count == 1 {
                let singleVpnID = newVpns[0].id
                if connectivitySettings.selectedVPNID != singleVpnID {
                    connectivitySettings.selectedVPNID = singleVpnID
                }
            }
        }
    }
    
    @ViewBuilder
    private var preferredVpnCard: some View {
        SettingsCard(title: "Preferred VPN") {
            VStack(alignment: .leading, spacing: 12) {
                if vpnViewModel.vpns.isEmpty {
                    Text("No VPN configurations found on this Mac. Please add a VPN connection in System Settings -> VPN first.")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                
                } else {
                    VStack(spacing: 8) {
                        ForEach(vpnViewModel.vpns) { vpn in
                            HStack(spacing: 10) {
                                if let bundleID = vpn.bundleID, let nsImage = getAppIcon(for: bundleID) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 36, height: 36)
                                } else {
                                    Image(systemName: "shield")
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundStyle(Color.gray)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(vpn.name)
                                    Text(vpn.type)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if connectivitySettings.selectedVPNID == vpn.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 20))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 20))
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.trailing, 10)
                            .padding(.leading, 6)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(connectivitySettings.selectedVPNID == vpn.id ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                            .onTapGesture {
                                connectivitySettings.selectedVPNID = vpn.id
                            }
                        }
                    }
                    .animation(.spring(response: 0.3), value: connectivitySettings.selectedVPNID)
                }
                Divider()
                    .opacity(0.6)
                
                Text("Select the VPN connection that you want to control from the notch.")
                    .font(.caption)
                    .foregroundColor(.gray)
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
