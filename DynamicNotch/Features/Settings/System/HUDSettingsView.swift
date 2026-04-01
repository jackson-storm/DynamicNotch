import SwiftUI

struct HUDSettingsView: View {
    @ObservedObject var settings: HUDSettingsStore

    var body: some View {
        SettingsPageScrollView {
            hudActivity
            hudStyle
        }
    }
    
    private var hudActivity: some View {
        SettingsCard(
            title: "HUD activity",
            subtitle: "Choose which system HUDs Dynamic Notch should replace."
        ) {
            SettingsToggleRow(
                title: "Brightness HUD",
                description: "Replace the system brightness HUD with DynamicNotch HUD.",
                systemImage: "sun.max.fill",
                color: .orange,
                isOn: $settings.isBrightnessHUDEnabled,
                accessibilityIdentifier: "settings.general.hud.brightness"
            )
            
            Divider()
            
            SettingsToggleRow(
                title: "Keyboard HUD",
                description: "Replace the keyboard backlight HUD with DynamicNotch HUD.",
                systemImage: "light.max",
                color: .orange,
                isOn: $settings.isKeyboardHUDEnabled,
                accessibilityIdentifier: "settings.general.hud.keyboard"
            )
            
            Divider()
            
            SettingsToggleRow(
                title: "Volume HUD",
                description: "Replace the system volume HUD with DynamicNotch HUD.",
                systemImage: "speaker.wave.2.fill",
                color: .orange,
                isOn: $settings.isVolumeHUDEnabled,
                accessibilityIdentifier: "settings.general.hud.volume"
            )
        }
    }
    
    private var hudStyle: some View {
        SettingsCard(
            title: "HUD style",
            subtitle: "Choose whether hardware HUD feedback appears in the notch or as a right-side floating bar."
        ) {
            
        }
    }
}
