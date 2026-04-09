import SwiftUI

struct HUDSettingsView: View {
    @ObservedObject var settings: HUDSettingsStore

    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }

    var body: some View {
        SettingsPageScrollView {
            hudActivity
            hudDuration
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
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Keyboard HUD",
                description: "Replace the keyboard backlight HUD with DynamicNotch HUD.",
                systemImage: "light.max",
                color: .orange,
                isOn: $settings.isKeyboardHUDEnabled,
                accessibilityIdentifier: "settings.general.hud.keyboard"
            )
            
            Divider()
                .opacity(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
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

    private var hudDuration: some View {
        SettingsCard(
            title: "HUD duration",
            subtitle: "Control how long each hardware HUD stays visible."
        ) {
            SettingsSliderRow(
                title: "Brightness duration",
                description: "Choose how long the brightness HUD stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.general.hud.brightness.duration",
                value: Binding(
                    get: { Double(settings.brightnessHUDDuration) },
                    set: { settings.brightnessHUDDuration = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isBrightnessHUDEnabled)
            .opacity(settings.isBrightnessHUDEnabled ? 1 : 0.5)

            Divider().opacity(0.6)

            SettingsSliderRow(
                title: "Keyboard duration",
                description: "Choose how long the keyboard backlight HUD stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.general.hud.keyboard.duration",
                value: Binding(
                    get: { Double(settings.keyboardHUDDuration) },
                    set: { settings.keyboardHUDDuration = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isKeyboardHUDEnabled)
            .opacity(settings.isKeyboardHUDEnabled ? 1 : 0.5)

            Divider().opacity(0.6)

            SettingsSliderRow(
                title: "Volume duration",
                description: "Choose how long the volume HUD stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.general.hud.volume.duration",
                value: Binding(
                    get: { Double(settings.volumeHUDDuration) },
                    set: { settings.volumeHUDDuration = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isVolumeHUDEnabled)
            .opacity(settings.isVolumeHUDEnabled ? 1 : 0.5)
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
                title: { $0.title },
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                hudStylePickerContent(for: style, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.general.hud.style")

            Divider().opacity(0.6)

            CustomPicker(
                selection: $settings.indicatorStyle,
                options: Array(HudIndicatorStyle.allCases),
                title: { $0.title },
                headerTitle: "Level indicator",
                headerDescription: "Choose whether the HUD level uses a bar or a circular ring.",
                itemHeight: 68
            ) { indicatorStyle, isSelected in
                hudIndicatorPickerContent(for: indicatorStyle, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.general.hud.indicatorStyle")

            Divider().opacity(0.6)

            SettingsToggleRow(
                title: "Colored level tint",
                description: "Use the dynamic green-to-red fill for the HUD level indicator instead of a plain white fill.",
                systemImage: "paintpalette.fill",
                color: .purple,
                isOn: $settings.isColoredLevelEnabled,
                accessibilityIdentifier: "settings.general.hud.coloredLevel"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

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
                    
                    pickerIndicator
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
                    
                    pickerIndicator
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
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 8)
            }
        }
    }

    @ViewBuilder
    private func hudIndicatorPickerContent(for indicatorStyle: HudIndicatorStyle, isSelected: Bool) -> some View {
        HudLevelIndicatorView(
            level: 72,
            indicatorStyle: indicatorStyle,
            usesColoredLevelTint: settings.isColoredLevelEnabled,
            barWidth: 38,
            barHeight: 5,
            circleSize: 20,
            circleLineWidth: 3
        )
        .scaleEffect(isSelected ? 1 : 0.97)
    }

    private var pickerIndicator: some View {
        HudLevelIndicatorView(
            level: 72,
            indicatorStyle: settings.indicatorStyle,
            usesColoredLevelTint: settings.isColoredLevelEnabled,
            barWidth: 30,
            barHeight: 4,
            circleSize: 16,
            circleLineWidth: 2.5
        )
    }

    private var pickerStrokeColor: Color {
        HudLevelStyling.previewStrokeTint(isEnabled: settings.isColoredLevelStrokeEnabled)
    }
}
