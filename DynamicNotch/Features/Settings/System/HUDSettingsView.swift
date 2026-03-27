import SwiftUI

struct HUDSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Custom HUD",
                subtitle: "Choose which system overlays Dynamic Notch should replace."
            ) {
                VStack {
                    SettingsToggleRow(
                        title: "Brightness HUD",
                        description: "Show the custom notch HUD for display brightness changes.",
                        systemImage: "sun.max.fill",
                        color: .orange,
                        isOn: $generalSettingsViewModel.isBrightnessHUDEnabled,
                        accessibilityIdentifier: "settings.general.hud.brightness"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Keyboard HUD",
                        description: "Show the custom notch HUD for keyboard backlight changes.",
                        systemImage: "light.max",
                        color: .orange,
                        isOn: $generalSettingsViewModel.isKeyboardHUDEnabled,
                        accessibilityIdentifier: "settings.general.hud.keyboard"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Volume HUD",
                        description: "Show the custom notch HUD for output volume changes.",
                        systemImage: "speaker.wave.2.fill",
                        color: .orange,
                        isOn: $generalSettingsViewModel.isVolumeHUDEnabled,
                        accessibilityIdentifier: "settings.general.hud.volume"
                    )
                }
            }
        }
    }
}
