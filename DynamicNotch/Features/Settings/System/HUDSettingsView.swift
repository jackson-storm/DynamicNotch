import SwiftUI

struct HUDSettingsView: View {
    @ObservedObject var settings: HUDSettingsStore

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Custom HUD",
                subtitle: "Choose which system HUDs Dynamic Notch should replace."
            ) {
                VStack {
                    SettingsToggleRow(
                        title: "Brightness HUD",
                        description: "Replace the system brightness HUD with the notch HUD.",
                        systemImage: "sun.max.fill",
                        color: .orange,
                        isOn: $settings.isBrightnessHUDEnabled,
                        accessibilityIdentifier: "settings.general.hud.brightness"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Keyboard HUD",
                        description: "Replace the keyboard backlight HUD with the notch HUD.",
                        systemImage: "light.max",
                        color: .orange,
                        isOn: $settings.isKeyboardHUDEnabled,
                        accessibilityIdentifier: "settings.general.hud.keyboard"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Volume HUD",
                        description: "Replace the system volume HUD with the notch HUD.",
                        systemImage: "speaker.wave.2.fill",
                        color: .orange,
                        isOn: $settings.isVolumeHUDEnabled,
                        accessibilityIdentifier: "settings.general.hud.volume"
                    )
                }
            }
        }
    }
}
