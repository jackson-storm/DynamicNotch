//
//  VpnSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 6/19/26.
//

import SwiftUI
import Combine
internal import AppKit

struct VpnSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    @StateObject private var vpnViewModel = VpnPageViewModel()
    
    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }
    
    private var vpnAppearanceStyle: Binding<VPNAppearanceStyle> {
        Binding(
            get: { connectivitySettings.isVPNDetailVisible ? .detailed : .compact },
            set: { connectivitySettings.isVPNDetailVisible = $0 == .detailed }
        )
    }
    
    private var vpnPreviewStrokeColor: Color {
        appearanceSettings.isShowNotchStrokeEnabled ? .white.opacity(0.2) : .clear
    }
    
    var body: some View {
        SettingsPageScrollView {
            vpnActivity
            vpnDuration
            preferredVpnCard
            vpnAppearance
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
    
    private var vpnActivity: some View {
        SettingsCard(title: "VPN activity") {
            SettingsToggleRow(
                title: "VPN temporary activity",
                description: "Show a short notification when a VPN connection becomes active.",
                systemImage: "network.badge.shield.half.filled",
                color: .blue,
                isOn: $connectivitySettings.isVpnTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.vpn"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "VPN disconnected temporary activity",
                description: "Show a short notification when a VPN connection becomes inactive.",
                systemImage: "network.badge.shield.half.filled",
                color: .blue,
                isOn: $connectivitySettings.isVpnDisconnectedTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.vpnDisconnected"
            )
        }
    }
    
    private var vpnDuration: some View {
        SettingsCard(title: "VPN duration") {
            SettingsSliderRow(
                title: "VPN duration",
                description: "Choose how long the VPN connection notification stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.vpn.duration",
                value: Binding(
                    get: { Double(connectivitySettings.vpnTemporaryActivityDuration) },
                    set: { connectivitySettings.vpnTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!connectivitySettings.isVpnTemporaryActivityEnabled)
            .opacity(connectivitySettings.isVpnTemporaryActivityEnabled ? 1 : 0.5)

            Divider()
                .opacity(0.6)

            SettingsSliderRow(
                title: "VPN disconnected duration",
                description: "Choose how long the VPN disconnection notification stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.vpnDisconnected.duration",
                value: Binding(
                    get: { Double(connectivitySettings.vpnDisconnectedTemporaryActivityDuration) },
                    set: { connectivitySettings.vpnDisconnectedTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!connectivitySettings.isVpnDisconnectedTemporaryActivityEnabled)
            .opacity(connectivitySettings.isVpnDisconnectedTemporaryActivityEnabled ? 1 : 0.5)
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
                                    VPNStatusRowView(
                                        isConnected: vpn.isConnected,
                                        connectedAt: vpn.isConnected ? vpnViewModel.connectedAt : nil
                                    )
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
    
    private var vpnAppearance: some View {
        SettingsCard(title: "VPN appearance") {
            CustomPicker(
                selection: vpnAppearanceStyle,
                options: Array(VPNAppearanceStyle.allCases),
                title: { $0.title },
                headerTitle: "VPN style",
                headerDescription: "Choose whether the VPN activity stays compact or shows tunnel details.",
                itemHeight: 72,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                vpnAppearancePickerContent(for: style, isSelected: isSelected, isTimerVisible: connectivitySettings.isVPNTimerVisible)
            }
            .accessibilityIdentifier("settings.activities.temporary.vpn.style")
        }
    }
    
    @ViewBuilder
    private func vpnAppearancePickerContent(for style: VPNAppearanceStyle, isSelected: Bool, isTimerVisible: Bool) -> some View {
        switch style {
        case .compact:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(vpnPreviewStrokeColor, lineWidth: 1)
                    }
                HStack {
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white.gradient)
                    
                    Spacer()
                    
                    Text(verbatim: "Active")
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(.leading, 6)
                .padding(.trailing, 10)
            }
            .frame(width: 200, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
            
        case .detailed:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(vpnPreviewStrokeColor, lineWidth: 1)
                    }
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "network.badge.shield.half.filled")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(verbatim: "Connected")
                                .lineLimit(1)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                            
                            Text("WireGuard VPN")
                                .lineLimit(1)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                
                    Text("00:10")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.orange)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 12)
            }
            .frame(width: 210, height: 50)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }
}

struct VPNStatusRowView: View {
    let isConnected: Bool
    let connectedAt: Date?
    
    @Environment(\.locale) private var locale
    @State private var elapsedString: String = "00:00"
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .onReceive(timer) { _ in
            updateElapsed()
        }
        .onAppear {
            updateElapsed()
        }
        .onChange(of: isConnected) { _, _ in
            updateElapsed()
        }
        .onChange(of: connectedAt) { _, _ in
            updateElapsed()
        }
    }
    
    private var statusText: String {
        let isRussian = locale.identifier.hasPrefix("ru")
        let isSpanish = locale.identifier.hasPrefix("es")
        let isChinese = locale.identifier.hasPrefix("zh")
        
        if isConnected {
            if isRussian {
                return "подключен в течение \(elapsedString)"
            } else if isSpanish {
                return "conectado durante \(elapsedString)"
            } else if isChinese {
                return "已连接 \(elapsedString)"
            } else {
                return "connected for \(elapsedString)"
            }
        } else {
            if isRussian {
                return "отключено"
            } else if isSpanish {
                return "desconectado"
            } else if isChinese {
                return "未连接"
            } else {
                return "disconnected"
            }
        }
    }
    
    private func updateElapsed() {
        guard isConnected, let connectedAt = connectedAt else {
            elapsedString = "00:00"
            return
        }
        let elapsed = Date().timeIntervalSince(connectedAt)
        let totalSeconds = max(0, Int(elapsed))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        elapsedString = String(format: "%02d:%02d", minutes, seconds)
    }
}
