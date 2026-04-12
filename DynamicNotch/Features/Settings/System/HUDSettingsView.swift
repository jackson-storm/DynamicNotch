import SwiftUI

struct HUDSettingsView: View {
    @ObservedObject var settings: HUDSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }

    private var isLevelStrokeLocked: Bool {
        applicationSettings.isDefaultActivityStrokeEnabled
    }

    var body: some View {
        SettingsPageScrollView {
            hudActivity
            hudDuration
            hudStyleCard
        }
    }
    
    private var hudActivity: some View {
        SettingsCard(title: "HUD activity") {
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
        SettingsCard(title: "HUD duration") {
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
        SettingsCard(title: "HUD appearance") {
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

            SettingsMenuRow(
                title: "Level indicator",
                description: "Choose whether the HUD level uses a bar or a circular ring.",
                options: Array(HudIndicatorStyle.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.general.hud.indicatorStyle",
                selection: $settings.indicatorStyle
            )

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

            SettingsStrokeToggleRow(
                title: "Level-based stroke color",
                description: "Tint the notch stroke using the current HUD level color instead of the default white stroke.",
                isOn: $settings.isColoredLevelStrokeEnabled,
                accessibilityIdentifier: "settings.general.hud.coloredStroke"
            )
            .disabled(isLevelStrokeLocked)
            .opacity(isLevelStrokeLocked ? 0.5 : 1)
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
                        .font(.system(size: 13, weight: .semibold))
                    
                    Text(verbatim: "Volume")
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(verbatim: "72")
                    
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
                        .font(.system(size: 13, weight: .semibold))
                    
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
                        .font(.system(size: 13, weight: .semibold))
                    
                    Spacer()
                    
                    Text(verbatim: "72")
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 8)
            }
        }
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
        guard applicationSettings.isShowNotchStrokeEnabled else {
            return .clear
        }

        return HudLevelStyling.previewStrokeTint(
            isEnabled: settings.isColoredLevelStrokeEnabled && !isLevelStrokeLocked
        )
    }
}
