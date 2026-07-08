import SwiftUI

struct HUDSettingsView: View {
    @ObservedObject var settings: HUDSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore

    private var layoutTypeBinding: Binding<HudLayoutType> {
        Binding(
            get: {
                settings.hudStyle == .expandedCompact || settings.hudStyle == .expandedDetailed ? .expanded : .compact
            },
            set: { newType in
                withAnimation(.easeInOut(duration: 0.15)) {
                    if newType == .expanded {
                        settings.hudStyle = .expandedCompact
                    } else {
                        settings.hudStyle = .compact
                    }
                }
            }
        )
    }

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
                color: .cyan,
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
                color: .cyan,
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
                color: .cyan,
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
            SettingsMenuRow(
                title: "HUD style",
                description: "settings.general.hud.layoutType.desc",
                options: Array(HudLayoutType.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.general.hud.layoutType",
                selection: layoutTypeBinding
            )

            Divider().opacity(0.6)

            if layoutTypeBinding.wrappedValue == .compact {
                CustomPicker(
                    selection: $settings.hudStyle,
                    options: [.standard, .compact, .minimal],
                    title: { $0.title },
                    lightBackgroundImage: Image("backgroundLight"),
                    darkBackgroundImage: Image("backgroundDark")
                ) { style, isSelected in
                    hudStylePickerContent(for: style, isSelected: isSelected)
                }
                .accessibilityIdentifier("settings.general.hud.style.compact")
            } else {
                CustomPicker(
                    selection: $settings.hudStyle,
                    options: [.expandedCompact, .expandedDetailed],
                    title: { $0.title },
                    itemHeight: 110,
                    lightBackgroundImage: Image("backgroundLight"),
                    darkBackgroundImage: Image("backgroundDark")
                ) { style, isSelected in
                    hudStylePickerContent(for: style, isSelected: isSelected)
                }
                .accessibilityIdentifier("settings.general.hud.style.expanded")
            }

            if layoutTypeBinding.wrappedValue == .compact {
                Divider().opacity(0.6)

                SettingsMenuRow(
                    title: "Level indicator",
                    description: "Choose whether the HUD level uses a bar or a circular ring.",
                    options: Array(HudIndicatorStyle.allCases),
                    optionTitle: { $0.title },
                    accessibilityIdentifier: "settings.general.hud.indicatorStyle",
                    selection: $settings.indicatorStyle
                )
            }

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "Indicator tint",
                description: "Choose the color used by the HUD level indicator.",
                options: Array(HudIndicatorTintStyle.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.general.hud.indicatorTint",
                selection: $settings.indicatorTintStyle
            )
            
            Divider().opacity(0.6)

            SettingsToggleRow(
                title: "Indicator glow",
                description: "Add a soft glow around the HUD level indicator.",
                systemImage: "sparkles",
                color: .yellow,
                isOn: $settings.isIndicatorGlowEnabled,
                accessibilityIdentifier: "settings.general.hud.indicatorGlow"
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
                    Text(verbatim: "Volume")
                        .lineLimit(1)
                    
                    Spacer()
                    
                    pickerIndicator(for: .standard)
                }
                .foregroundStyle(.white)
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
                    
                    pickerIndicator(for: .compact)
                }
                .foregroundStyle(.white)
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
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
            }

        case .expandedCompact:
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.black)
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(strokeColor, lineWidth: 1)
                    }
                
                VStack {
                    Spacer()
                    
                    ZStack {
                        pickerIndicator(for: .expandedCompact, barWidth: 60, barHeight: 6)
                        
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 14))
                            
                            Spacer()
                            
                            Text(verbatim: "72")
                                .font(.system(size: 14, design: .rounded))
                        }
                    }
                    .frame(width: 120)
                }
                .padding(.bottom, 8)
            }
            .foregroundStyle(.white)
            .frame(width: 150, height: 48)

        case .expandedDetailed:
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.black)
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(strokeColor, lineWidth: 1)
                    }
                
                VStack {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(verbatim: "Volume")
                            .font(.system(size: 12))
                            .padding(.horizontal, 10)
                        
                        ZStack {
                            pickerIndicator(for: .expandedDetailed, barWidth: 60, barHeight: 6)
                            
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14))
                                
                                Spacer()
                                
                                Text(verbatim: "72")
                                    .font(.system(size: 14, design: .rounded))
                            }
                        }
                        .frame(width: 120)
                        .padding(.horizontal, 10)
                    }
                }
                .padding(.bottom, 8)
            }
            .foregroundStyle(.white)
            .frame(width: 150, height: 48)
        }
    }

    private func pickerIndicator(for style: HudStyle, barWidth: CGFloat = 30, barHeight: CGFloat = 4) -> some View {
        let isExpanded = style == .expandedCompact || style == .expandedDetailed
        return HudLevelIndicatorView(
            level: 72,
            indicatorStyle: isExpanded ? .bar : settings.indicatorStyle,
            tintStyle: settings.indicatorTintStyle,
            showsGlow: settings.isIndicatorGlowEnabled,
            barWidth: barWidth,
            barHeight: barHeight,
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
