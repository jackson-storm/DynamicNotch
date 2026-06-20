//
//  VpnPageNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/19/26.
//

import SwiftUI
import Combine
internal import AppKit

struct VpnPageNotchView: View {
    @StateObject private var viewModel = VpnPageViewModel()
    @AppStorage("settings.vpn.selectedID") private var selectedVPNID: String = ""
    
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeString: String = "00:00"
    
    let notchViewModel: NotchViewModel
    
    private func updateTimer() {
        guard let startDate = viewModel.connectedAt else {
            timeString = "00:00"
            return
        }
        let elapsed = Date().timeIntervalSince(startDate)
        timeString = elapsed.formattedDuration
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            if viewModel.vpns.isEmpty {
                if viewModel.isLoading {
                    progressView
                } else {
                    emptyStateView
                }
            } else if let preferredVPN = viewModel.vpns.first(where: { $0.id == selectedVPNID }) {
                featuredVPNView(for: preferredVPN)
            } else if let firstActive = viewModel.vpns.first(where: { $0.isConnected }) {
                featuredVPNView(for: firstActive)
            } else {
                noSelectionView
            }
        }
        .onAppear {
            viewModel.startMonitoring()
            updateTimer()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
    
    @ViewBuilder
    private func featuredVPNView(for vpn: VPNConfiguration) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if let bundleID = vpn.bundleID, let nsImage = getAppIcon(for: bundleID) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .cornerRadius(6)
                    
                } else {
                    Image(systemName: vpn.isConnected ? "shield.fill" : "shield")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(vpn.isConnected ? Color.green : Color.gray)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    MarqueeText(
                        .constant(vpn.name),
                        font: .system(size: 16, weight: .medium),
                        nsFont: .headline,
                        textColor: .white.opacity(0.8),
                        backgroundColor: .clear,
                        minDuration: 2.0,
                        frameWidth: 120
                    )
                    
                    MarqueeText(
                    .constant(vpn.type),
                    font: .system(size: 11),
                    nsFont: .body,
                    textColor: .white.opacity(0.5),
                    backgroundColor: .clear,
                    minDuration: 3.0,
                    frameWidth: 120
                    )
                }
                
                Spacer()
                
                if vpn.isConnected {
                    Text(timeString)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.orange)
                        .onReceive(timer) { _ in
                            updateTimer()
                        }
                } else {
                    Text("--:--")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Button(action: {
                    SettingsWindowController.shared.showWindow(selecting: .vpn)
                    notchViewModel.dismissActiveContent()
                }) {
                    Text(verbatim: "Open Settings")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(PrimaryButtonStyle(
                    height: 35,
                    backgroundColor: Color.gray.opacity(0.2),
                    foregroundColor: .white
                ))
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.toggleVPN(vpn)
                    }
                }) {
                    Text(verbatim: vpn.isConnected ? "Disconnect" : "Connect")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(PrimaryButtonStyle(
                    height: 35,
                    backgroundColor: vpn.isConnected ? Color.red.opacity(0.2) : Color.blue.opacity(0.2),
                    foregroundColor: vpn.isConnected ? .red : .blue
                ))
            }
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 5)
    }
    
    @ViewBuilder
    private var noSelectionView: some View {
        VStack(spacing: 8) {
            Image(systemName: "network.badge.shield.half.filled")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.gray.opacity(0.8))
            
            Text(verbatim: "No VPN Selected")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(verbatim: "Please select your preferred VPN in Settings.")
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 12)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "network.badge.shield.half.filled")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.gray.opacity(0.8))
            
            Text(verbatim: "No VPN configurations found")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(verbatim: "Add a VPN in macOS Settings -> VPN.")
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 12)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var progressView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
        .frame(height: 115)
    }
    
    private func getAppIcon(for bundleID: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
