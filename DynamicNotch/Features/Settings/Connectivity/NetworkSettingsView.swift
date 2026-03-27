import SwiftUI

struct NetworkSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Live network activity",
                subtitle: "Persistent status that stays visible while tethering remains active."
            ) {
                SettingsToggleRow(
                    title: "Personal Hotspot live activity",
                    description: "Show hotspot status as a long-lived activity while the hotspot remains enabled.",
                    systemImage: "personalhotspot",
                    color: .green,
                    isOn: $generalSettingsViewModel.isHotspotLiveActivityEnabled,
                    accessibilityIdentifier: "settings.activities.live.hotspot"
                )
            }

            SettingsCard(
                title: "Temporary network activity",
                subtitle: "Short confirmations for wireless and secure network connections."
            ) {
                VStack {
                    SettingsToggleRow(
                        title: "Wi-Fi temporary activity",
                        description: "Display a brief toast when Wi-Fi reconnects.",
                        systemImage: "wifi",
                        color: .blue,
                        isOn: $generalSettingsViewModel.isWifiTemporaryActivityEnabled,
                        accessibilityIdentifier: "settings.activities.temporary.wifi"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "VPN temporary activity",
                        description: "Show a temporary confirmation when a VPN tunnel becomes active.",
                        systemImage: "network",
                        color: .blue,
                        isOn: $generalSettingsViewModel.isVpnTemporaryActivityEnabled,
                        accessibilityIdentifier: "settings.activities.temporary.vpn"
                    )
                }
            }
        }
    }
}
