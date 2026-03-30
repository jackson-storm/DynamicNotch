import SwiftUI

struct NetworkSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    
    var body: some View {
        SettingsPageScrollView {
            networkActivity
            networkAppearance
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
                isOn: $generalSettingsViewModel.isWifiTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.wifi"
            )
            
            Divider()
            
            SettingsToggleRow(
                title: "VPN temporary activity",
                description: "Show a short notification when a VPN connection becomes active.",
                systemImage: "network",
                color: .blue,
                isOn: $generalSettingsViewModel.isVpnTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.vpn"
            )
            
            Divider()
            
            SettingsToggleRow(
                title: "Personal Hotspot live activity",
                description: "Show a live activity while Personal Hotspot is enabled.",
                systemImage: "personalhotspot",
                color: .green,
                isOn: $generalSettingsViewModel.isHotspotLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.hotspot"
            )
        }
    }
    
    private var networkAppearance: some View {
        SettingsCard(
            title: "Network appearance",
            subtitle: "Preview the hotspot notch and adjust its accent stroke."
        ) {
            NotchPreview(
                width: 270,
                height: 38,
                showsStroke: generalSettingsViewModel.isShowNotchStrokeEnabled,
                strokeColor: generalSettingsViewModel.isHotspotDefaultStrokeEnabled ?
                    .white.opacity(0.2) :
                        .green.opacity(0.3),
                strokeWidth: CGFloat(generalSettingsViewModel.notchStrokeWidth)
            ) {
                HotspotPreviewNotchView()
            }
            
            SettingsToggleRow(
                title: "Use default stroke color",
                description: "Use the default notch stroke color instead of the green hotspot accent.",
                systemImage: "paintbrush.pointed.fill",
                color: .indigo,
                isOn: $generalSettingsViewModel.isHotspotDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.hotspot.defaultStroke"
            )
        }
    }
}
