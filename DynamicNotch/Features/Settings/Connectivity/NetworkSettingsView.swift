import SwiftUI

struct NetworkSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
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
        SettingsCard(
            title: "Network activity",
            subtitle: "Control when network notifications appear and how the VPN activity looks in the notch."
        ) {
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
        SettingsCard(
            title: "Network duration",
            subtitle: "Control when network notifications appear and how the VPN activity looks in the notch."
        ) {
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
        SettingsCard(
            title: "VPN appearance",
            subtitle: "Control when network notifications appear and how the VPN activity looks in the notch."
        ) {
            VpnActivityPreview(
                connectivitySettings: connectivitySettings,
                appearanceSettings: appearanceSettings
            )
            
            Divider().opacity(0.6)
            
            SettingsToggleRow(
                title: "Show VPN details",
                description: "Expand the VPN notification to reveal the tunnel name and extra status.",
                systemImage: "rectangle.expand.vertical",
                color: .indigo,
                isOn: $connectivitySettings.isVPNDetailVisible,
                accessibilityIdentifier: "settings.activities.temporary.vpn.details"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Show VPN timer",
                description: "Show the elapsed session timer inside the detailed VPN notification.",
                systemImage: "timer",
                color: .orange,
                isOn: $connectivitySettings.isVPNTimerVisible,
                accessibilityIdentifier: "settings.activities.temporary.vpn.timer"
            )
            .disabled(!connectivitySettings.isVPNDetailVisible)
            .opacity(connectivitySettings.isVPNDetailVisible ? 1 : 0.5)
            
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
        SettingsCard(
            title: "Hotspot appearance",
            subtitle: "Choose how the Personal Hotspot live activity looks while it is active."
        ) {
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
                            .stroke(.green.opacity(0.2), lineWidth: 1)
                    }
                
                HStack {
                    Image(systemName: "personalhotspot")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.green)
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            .frame(width: 160, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
            
        case .detailed:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(.green.opacity(0.2), lineWidth: 1)
                    }
                
                HStack(spacing: 10) {
                    Image(systemName: "personalhotspot")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.green)
                    
                    Spacer(minLength: 8)
                    
                    Text(verbatim: "On")
                        .font(.system(size: 11))
                        .foregroundStyle(.green.opacity(0.8))
                }
                .padding(.horizontal, 10)
            }
            .frame(width: 160, height: 30)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }
}

private struct VpnActivityPreview: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    private var notchWidth: CGFloat {
        if connectivitySettings.isVPNDetailVisible {
            return connectivitySettings.isVPNTimerVisible ? 340 : 320
        }
        return 300
    }
    
    private var strokeColor: Color {
        appearanceSettings.isShowNotchStrokeEnabled ? .white.opacity(0.2) : .clear
    }
    
    private var previewConnectedAt: Date {
        .now.addingTimeInterval(-2318)
    }
    
    var body: some View {
        SettingsNotchPreview(
            width: notchWidth,
            height: 38,
            previewWidth: .infinity,
            previewHeight: 80,
            backgroundStyle: appearanceSettings.notchBackgroundStyle,
            showsStroke: appearanceSettings.isShowNotchStrokeEnabled,
            strokeColor: strokeColor,
            strokeWidth: CGFloat(appearanceSettings.notchStrokeWidth),
            lightBackgroundImage: Image("backgroundLight"),
            darkBackgroundImage: Image("backgroundDark")
        ) {
            VpnActivityPreviewContent(
                isShowingDetail: connectivitySettings.isVPNDetailVisible,
                isTimerVisible: connectivitySettings.isVPNTimerVisible,
                vpnName: "WireGuard",
                connectedAt: previewConnectedAt
            )
        }
    }
}

private struct VpnActivityPreviewContent: View {
    let isShowingDetail: Bool
    let isTimerVisible: Bool
    let vpnName: String
    let connectedAt: Date?
    
    private func formattedElapsedTime(since startDate: Date, currentDate: Date) -> String {
        let totalSeconds = max(0, Int(currentDate.timeIntervalSince(startDate)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        HStack {
            leftContent
            Spacer()
            rightContent
        }
        .padding(.horizontal, 16)
        .font(.system(size: 14))
    }
    
    @ViewBuilder
    private var leftContent: some View {
        if !isShowingDetail {
            HStack {
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                
                Text("VPN")
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            }
        } else {
            Text(vpnName)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private var rightContent: some View {
        if !isShowingDetail {
            Text("Connected")
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
        } else if isTimerVisible {
            HStack {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(connectedAt.map { formattedElapsedTime(since: $0, currentDate: context.date) } ?? "--:--:--")
                        .monospacedDigit()
                        .foregroundStyle(.orange.gradient)
                }
                
                Image(systemName: "gauge.with.needle")
                    .font(.system(size: 18))
                    .foregroundStyle(.orange)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.orange)
                
                Text("Protected")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }
        }
    }
}
