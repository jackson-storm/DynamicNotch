import SwiftUI

struct HUDSettingsView: View {
    @ObservedObject var settings: HUDSettingsStore

    var body: some View {
        SettingsPageScrollView {
            hudActivity
            hudStyleCard
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
    
    private var hudStyleCard: some View {
        SettingsCard(
            title: "HUD appearance",
            subtitle: "Choose how hardware HUD feedback is laid out inside the notch."
        ) {
            CustomPicker(
                selection: $settings.hudStyle,
                options: Array(HudStyle.allCases),
                title: { $0.title }
            ) { style, isSelected in
                hudStylePickerContent(for: style, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.general.hud.style")

            Divider()

            SettingsToggleRow(
                title: "Colored level tint",
                description: "Use the dynamic green-to-red fill for the HUD level bar instead of a plain white fill.",
                systemImage: "paintpalette.fill",
                color: .purple,
                isOn: $settings.isColoredLevelEnabled,
                accessibilityIdentifier: "settings.general.hud.coloredLevel"
            )

            Divider()

            SettingsToggleRow(
                title: "Level-based stroke color",
                description: "Tint the notch stroke using the current HUD level color instead of the default white stroke.",
                systemImage: "paintbrush.fill",
                color: .pink,
                isOn: $settings.isColoredLevelStrokeEnabled,
                accessibilityIdentifier: "settings.general.hud.coloredStroke"
            )
        }
    }

    @ViewBuilder
    private func hudStylePickerContent(for style: HudStyle, isSelected: Bool) -> some View {
        let levelFill = pickerLevelFill
        let levelFillShadow = levelFill.opacity(settings.isColoredLevelEnabled ? 0.35 : 0.18)
        let strokeColor = pickerStrokeColor

        switch style {
        case .standard:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(strokeColor, lineWidth: 1)
                    }
                    .frame(height: 30)
                
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("Volume")
                        .font(.system(size: 10))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("72")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                    
                    Capsule()
                        .fill(levelFill)
                        .frame(width: 30, height: 4)
                        .shadow(color: levelFillShadow, radius: 4, y: 0)
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 8)
            }

        case .compact:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(strokeColor, lineWidth: 1)
                    }
                    .frame(height: 30)
                
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Spacer()
                    
                    Capsule()
                        .fill(levelFill)
                        .frame(width: 34, height: 4)
                        .shadow(color: levelFillShadow, radius: 4, y: 0)
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 8)
            }

        case .minimal:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(strokeColor, lineWidth: 1)
                    }
                    .frame(height: 30)
                
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Spacer()
                    
                    Text("72")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 8)
            }
        }
    }

    private var pickerLevelFill: Color {
        HudLevelStyling.previewFillTint(isEnabled: settings.isColoredLevelEnabled)
    }

    private var pickerStrokeColor: Color {
        HudLevelStyling.previewStrokeTint(isEnabled: settings.isColoredLevelStrokeEnabled)
    }
}
