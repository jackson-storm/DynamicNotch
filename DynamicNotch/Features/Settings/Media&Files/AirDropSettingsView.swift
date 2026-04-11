import SwiftUI

struct AirDropSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            airDropActivity
        }
    }
    
    private var airDropActivity: some View {
        SettingsCard(
            title: "AirDrop activity",
            subtitle: "Show a dedicated drop target in the notch while sharing files with AirDrop."
        ) {
            SettingsToggleRow(
                title: "AirDrop live activity",
                description: "Show the AirDrop drop target when you drag files over the notch.",
                imageName: "airdrop.white",
                color: .blue,
                isOn: $mediaSettings.isAirDropLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.airDrop"
            )
        }
    }
}
