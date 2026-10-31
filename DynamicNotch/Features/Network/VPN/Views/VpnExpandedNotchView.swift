//
//  VpnExpandedNotchView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/19/26.
//

import SwiftUI
import Combine
internal import AppKit

struct VpnExpandedNotchView: View {
    let notchViewModel: NotchViewModel
    @ObservedObject var viewModel: VpnViewModel
    
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    @Environment(\.notchScale) private var notchScale
    @Environment(\.locale) private var locale
    
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeString: String = "00:00"
    
    var body: some View {
        VStack {
            HStack(spacing: 14) {
                if let vpn = viewModel.vpns.first(where: { $0.isConnected }) {
                    logoOrFlag(for: vpn)
                    
                    description(for: vpn)
                        .padding(.top, isNotchlessScreen ? 15 : 0)
                    
                    Spacer()
                    
                    button(for: vpn)
                }
            }
        }
        .padding(.top, isNotchlessScreen ? 0 : 25)
        .padding(.leading, isNotchlessScreen ? 15 : 40)
        .padding(.trailing, isNotchlessScreen ? 15 : 34)
        .onReceive(timer) { _ in
            updateTimer()
        }
        .onAppear {
            viewModel.startMonitoring()
            updateTimer()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
        .onChange(of: viewModel.connectedAt) { _, _ in
            updateTimer()
        }
    }
    
    private func description(for vpn: VPNConfiguration) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(locale.dn("notch.vpn.ip", fallback: "IP:"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                
                Text(vpnTitle(for: vpn))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 10, height: 10)
                
                Text(locale.dnFormat("notch.vpn.connectedTime", fallback: "Connected (%@)", timeString))
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
    }
    
    @ViewBuilder
    private func logoOrFlag(for vpn: VPNConfiguration) -> some View {
        if let flag = viewModel.countryFlag ?? viewModel.inferredFlag(for: vpn) {
            Text(flag)
                .font(.system(size: 50))
        } else {
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private func button(for vpn: VPNConfiguration) -> some View {
        Button(action: {
            viewModel.toggleVPN(vpn)
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Vpn.vpn.id))
        }) {
            Image(systemName: "network.slash")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.red)
        }
        .buttonStyle(PrimaryButtonStyle(width: 50, height: 50, backgroundColor: .red.opacity(0.25)))    }
    
    private func vpnTitle(for vpn: VPNConfiguration) -> String {
        if vpn.isConnected {
            if let ip = viewModel.currentIP, !ip.isEmpty {
                return ip
            } else if let serverAddress = vpn.serverAddress, !serverAddress.isEmpty {
                return serverAddress
            }
        }
        return vpn.name
    }
    
    private func updateTimer() {
        guard let startDate = viewModel.connectedAt else {
            timeString = "00:00"
            return
        }
        let elapsed = Date().timeIntervalSince(startDate)
        timeString = elapsed.formattedDuration
    }
}
