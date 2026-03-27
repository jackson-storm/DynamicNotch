import SwiftUI

struct AirDropSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "AirDrop activity",
                subtitle: "Control the dedicated drop target shown while sharing files through the notch."
            ) {
                SettingsToggleRow(
                    title: "AirDrop live activity",
                    description: "Show an AirDrop live activity when you drag a file over the notch before sharing it.",
                    systemImage: "dot.radiowaves.left.and.right",
                    color: .cyan,
                    isOn: $generalSettingsViewModel.isAirDropLiveActivityEnabled,
                    accessibilityIdentifier: "settings.activities.live.airDrop"
                )
            }
        }
    }
}
