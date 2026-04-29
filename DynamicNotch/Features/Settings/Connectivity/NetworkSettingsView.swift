import SwiftUI

struct NetworkSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }
    
    private var vpnAppearanceStyle: Binding<VPNAppearanceStyle> {
        Binding(
            get: { connectivitySettings.isVPNDetailVisible ? .detailed : .compact },
            set: { connectivitySettings.isVPNDetailVisible = $0 == .detailed }
        )
    }
    
    private var isDetailedVPNStyle: Bool {
        vpnAppearanceStyle.wrappedValue == .detailed
    }

    private var isHotspotDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }

    private var hotspotPreviewStrokeColor: Color {
        guard appearanceSettings.isShowNotchStrokeEnabled else {
            return .clear
        }

        if appearanceSettings.isDefaultActivityStrokeEnabled || connectivitySettings.isHotspotDefaultStrokeEnabled {
            return .white.opacity(0.2)
        }

        return .green.opacity(0.2)
    }

    private var vpnPreviewStrokeColor: Color {
        appearanceSettings.isShowNotchStrokeEnabled ? .white.opacity(0.2) : .clear
    }
    
    var body: some View {
        SettingsPageScrollView {
            networkActivity
            networkDuration
            vpnAppearance
            hotspotAppearance
        }
    }
    
    private var networkActivity: some View {
        SettingsCard(title: "Network activity") {
            SettingsToggleRow(
                title: "Wi-Fi temporary activity",
                description: "Show a short notification when Wi-Fi reconnects.",
                systemImage: "wifi",
                color: .blue,
                isOn: $connectivitySettings.isWifiTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.wifi"
            )
            
            Divider()
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "VPN temporary activity",
                description: "Show a short notification when a VPN connection becomes active.",
                systemImage: "network",
                color: .blue,
                isOn: $connectivitySettings.isVpnTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.vpn"
            )
            
            Divider()
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "No internet temporary activity",
                description: "Show a short notification when your Mac loses internet access.",
                systemImage: "wifi.slash",
                color: .red,
                isOn: $connectivitySettings.isNoInternetTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.noInternet"
            )

            Divider()
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Personal Hotspot live activity",
                description: "Show a live activity while Personal Hotspot is enabled.",
                systemImage: "personalhotspot",
                color: .green,
                isOn: $connectivitySettings.isHotspotLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.hotspot"
            )
        }
    }
    
    private var networkDuration: some View {
        SettingsCard(title: "Network duration") {
            SettingsSliderRow(
                title: "Wi-Fi duration",
                description: "Choose how long the Wi-Fi reconnect notification stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.wifi.duration",
                value: Binding(
                    get: { Double(connectivitySettings.wifiTemporaryActivityDuration) },
                    set: { connectivitySettings.wifiTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!connectivitySettings.isWifiTemporaryActivityEnabled)
            .opacity(connectivitySettings.isWifiTemporaryActivityEnabled ? 1 : 0.5)
            
            Divider().opacity(0.6)
            
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
        }
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
            
            Divider()
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Show VPN timer",
                description: "Show the elapsed session timer inside the detailed VPN notification.",
                systemImage: "timer",
                color: .orange,
                isOn: $connectivitySettings.isVPNTimerVisible,
                accessibilityIdentifier: "settings.activities.temporary.vpn.timer"
            )
            .disabled(!isDetailedVPNStyle)
            .opacity(isDetailedVPNStyle ? 1 : 0.5)
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Only notify on network change",
                description: "Only show Wi-Fi or VPN notifications when the connected network actually changes.",
                systemImage: "point.3.connected.trianglepath.dotted",
                color: .red,
                isOn: $connectivitySettings.isOnlyNotifyOnNetworkChangeEnabled,
                accessibilityIdentifier: "settings.activities.temporary.network.changeOnly"
            )
        }
    }
    
    private var hotspotAppearance: some View {
        SettingsCard(title: "Hotspot appearance") {
            CustomPicker(
                selection: $connectivitySettings.hotspotAppearanceStyle,
                options: Array(HotspotAppearanceStyle.allCases),
                title: { $0.title },
                headerTitle: "Appearance",
                headerDescription: "Choose whether the hotspot activity stays minimal or shows more status.",
                itemHeight: 72,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                hotspotAppearancePickerContent(for: style, isSelected: isSelected)
            }

            Divider().opacity(0.6)

            SettingsStrokeToggleRow(
                title: "Default stroke",
                description: "Use the standard white notch stroke instead of the hotspot accent stroke.",
                isOn: $connectivitySettings.isHotspotDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.hotspot.defaultStroke"
            )
            .disabled(isHotspotDefaultStrokeLocked)
            .opacity(isHotspotDefaultStrokeLocked ? 0.5 : 1)
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
                        .foregroundStyle(Color.accentColor)
                    
                    Text("VPN")
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(verbatim: "Connected")
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(.leading, 6)
                .padding(.trailing, 10)
            }
            .frame(height: 30)
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
                    Text("WireGuard")
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if isTimerVisible {
                        HStack(spacing: 6) {
                            Text("00:13:06")
                                .foregroundStyle(.orange.gradient)
                            
                            Image(systemName: "gauge.with.needle")
                                .font(.system(size: 16, weight: .semibold))
                                .lineLimit(1)
                                .foregroundStyle(.orange.gradient)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.orange)
                            
                            Text(verbatim: "Protected")
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.trailing, isTimerVisible ? 6 : 10)
                .padding(.leading, 10)
            }
            .frame(height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }
    
    @ViewBuilder
    private func hotspotAppearancePickerContent(for style: HotspotAppearanceStyle, isSelected: Bool) -> some View {
        switch style {
        case .minimal:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(hotspotPreviewStrokeColor, lineWidth: 1)
                    }
                
                HStack {
                    Image(systemName: "personalhotspot")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                    
                    Spacer()
                }
                .padding(.horizontal, 7)
            }
            .frame(width: 160, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
            
        case .detailed:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(hotspotPreviewStrokeColor, lineWidth: 1)
                    }
                
                HStack(spacing: 10) {
                    Image(systemName: "personalhotspot")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                    
                    Spacer()
                    
                    Text(verbatim: "On")
                        .foregroundStyle(.green.opacity(0.8))
                }
                .padding(.leading, 7)
                .padding(.trailing, 10)
            }
            .frame(width: 160, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }
}
