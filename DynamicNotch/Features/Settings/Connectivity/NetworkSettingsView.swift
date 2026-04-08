import SwiftUI

struct NetworkSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            networkActivity
        }
    }
    
    private var networkActivity: some View {
        SettingsCard(
            title: "Network activity",
            subtitle: "Control network-related live and temporary activities."
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
                .padding(.leading, 43)
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
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Personal Hotspot live activity",
                description: "Show a live activity while Personal Hotspot is enabled.",
                systemImage: "personalhotspot",
                color: .blue,
                isOn: $connectivitySettings.isHotspotLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.hotspot"
            )
        }
    }
}
