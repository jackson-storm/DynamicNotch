import SwiftUI

struct AirDropSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    private var isDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }
    
    var body: some View {
        SettingsPageScrollView {
            airDropActivity
        }
    }
    
    private var airDropActivity: some View {
        SettingsCard(title: "AirDrop activity") {
            SettingsToggleRow(
                title: "AirDrop live activity",
                description: "Show the AirDrop drop target when you drag files over the notch.",
                imageName: "airdrop.white",
                color: .blue,
                isOn: $mediaSettings.isAirDropLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.airDrop"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsStrokeToggleRow(
                title: "Default stroke",
                description: "Use the standard white notch stroke instead of the blue AirDrop stroke.",
                isOn: $mediaSettings.isAirDropDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.airDrop.defaultStroke"
            )
            .disabled(isDefaultStrokeLocked)
            .opacity(isDefaultStrokeLocked ? 0.5 : 1)
        }
    }
}
