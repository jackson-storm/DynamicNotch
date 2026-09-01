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
        SettingsCard(title: "settings.hud.card.activity") {
            SettingsToggleRow(
                title: "settings.hud.brightness.title",
                description: "settings.hud.brightness.desc",
                systemImage: "sun.max.fill",
                color: .teal.opacity(0.9),
                isOn: $settings.isBrightnessHUDEnabled,
                accessibilityIdentifier: "settings.general.hud.brightness"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.hud.keyboard.title",
                description: "settings.hud.keyboard.desc",
                systemImage: "light.max",
                color: .teal.opacity(0.9),
                isOn: $settings.isKeyboardHUDEnabled,
                accessibilityIdentifier: "settings.general.hud.keyboard"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "settings.hud.volume.title",
                description: "settings.hud.volume.desc",
                systemImage: "speaker.wave.2.fill",
                color: .teal.opacity(0.9),
                isOn: $settings.isVolumeHUDEnabled,
                accessibilityIdentifier: "settings.general.hud.volume"
            )
        }
    }

    private var hudDuration: some View {
        SettingsCard(title: "settings.hud.card.duration") {
            SettingsSliderRow(
                title: "settings.hud.brightnessDuration.title",
                description: "settings.hud.brightnessDuration.desc",
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
                title: "settings.hud.keyboardDuration.title",
                description: "settings.hud.keyboardDuration.desc",
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
                title: "settings.hud.volumeDuration.title",
                description: "settings.hud.volumeDuration.desc",
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
        SettingsCard(title: "settings.hud.card.appearance") {
            SettingsMenuRow(
                title: "settings.hud.style.title",
                description: "settings.hud.style.desc",
                options: Array(HudLayoutType.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.hud.layoutType.title",
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
                .accessibilityIdentifier("settings.hud.style.title.compact")
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
                .accessibilityIdentifier("settings.hud.style.title.expanded")
            }

            if layoutTypeBinding.wrappedValue == .compact {
                Divider().opacity(0.6)

                SettingsMenuRow(
                    title: "settings.hud.indicatorStyle.title",
                    description: "settings.hud.indicatorStyle.desc",
                    options: Array(HudIndicatorStyle.allCases),
                    optionTitle: { $0.title },
                    accessibilityIdentifier: "settings.general.hud.indicatorStyle",
                    selection: $settings.indicatorStyle
                )
            }

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.hud.indicatorTintStyle.title",
                description: "settings.hud.indicatorTintStyle.desc",
                options: Array(HudIndicatorTintStyle.allCases),
                optionTitle: { $0.title },
                accessibilityIdentifier: "settings.general.hud.indicatorTint",
                selection: $settings.indicatorTintStyle
            )
            
            Divider().opacity(0.6)
            
            SettingsStrokeToggleRow(
                title: "settings.hud.levelStrokeColor.title",
                description: "settings.hud.levelStrokeColor.desc",
                isOn: $settings.isColoredLevelStrokeEnabled,
                accessibilityIdentifier: "settings.general.hud.coloredStroke"
            )
            .disabled(isLevelStrokeLocked)
            .opacity(isLevelStrokeLocked ? 0.5 : 1)
            
            Divider().opacity(0.6)
            
            SettingsToggleRow(
                title: "settings.hud.volumeSoundFeedback.title",
                description: "settings.hud.volumeSoundFeedback.desc",
                systemImage: "speaker.wave.2.fill",
                color: .red,
                isOn: $settings.isVolumeFeedbackSoundEnabled,
                accessibilityIdentifier: "settings.general.hud.volumeFeedbackSound"
            )
            .disabled(!settings.isVolumeHUDEnabled)
            .opacity(settings.isVolumeHUDEnabled ? 1 : 0.5)
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "settings.hud.indicatorGlow.title",
                description: "settings.hud.indicatorGlow.desc",
                systemImage: "sparkles",
                color: .yellow,
                isOn: $settings.isIndicatorGlowEnabled,
                accessibilityIdentifier: "settings.general.hud.indicatorGlow"
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
