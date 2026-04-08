import SwiftUI

struct LockScreenSettingsView: View {
    @ObservedObject var settings: LockScreenFeatureSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            lockScreenActivity
            notchAppearance
            widgetAppearance
        }
    }
    
    private var lockScreenActivity: some View {
        SettingsCard(
            title: "Lock screen activity",
            subtitle: "Control the lock-screen live activity, sound, and detached media panel."
        ) {
            SettingsToggleRow(
                title: "Lock screen live activity",
                description: "Show the lock-screen live activity during lock and unlock transitions.",
                systemImage: "lock.fill",
                color: .black,
                isOn: $settings.isLockScreenLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.lockScreen.liveActivity"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Lock screen media panel",
                description: "Show the detached media panel on the lock screen while playback is active.",
                systemImage: "play.rectangle.fill",
                color: .pink,
                isOn: $settings.isLockScreenMediaPanelEnabled,
                accessibilityIdentifier: "settings.activities.lockScreen.mediaPanel"
            )
        }
    }
    
    private var notchAppearance: some View {
        SettingsCard(
            title: "Notch appearance",
            subtitle: "Choose how the lock-screen activity is laid out inside the notch."
        ) {
            CustomPicker(
                selection: $settings.lockScreenStyle,
                options: Array(LockScreenStyle.allCases),
                title: { $0.title },
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                lockScreenStylePickerContent(for: style, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.activities.lockScreen.style")

            Divider().opacity(0.6)

            SettingsToggleRow(
                title: "Lock screen sound",
                description: "Play a sound when locking or unlocking your Mac.",
                systemImage: "speaker.wave.2.fill",
                color: .red,
                isOn: $settings.isLockScreenSoundEnabled,
                accessibilityIdentifier: "settings.activities.lockScreen.sound"
            )
        }
    }
    
    private var widgetAppearance: some View {
        SettingsCard(
            title: "Widget appearance",
            subtitle: "Choose the background style used by the lock-screen media widget."
        ) {
            CustomPicker(
                selection: $settings.widgetAppearanceStyle,
                options: LockScreenWidgetAppearanceStyle.availableOptions,
                title: { $0.title },
                itemHeight: 128,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                widgetAppearancePickerContent(for: style, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.activities.lockScreen.widgetAppearance")
        }
    }

    @ViewBuilder
    private func lockScreenStylePickerContent(for style: LockScreenStyle, isSelected: Bool) -> some View {
        ZStack {
            Capsule()
                .fill(.black)
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
                .frame(height: 30)

            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))

                Spacer()
                
                if style == .enlarged {
                    Text("Locked")
                        .font(.system(size: 10))
                }
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 10)
        }
        .frame(width: 140)
        .scaleEffect(isSelected ? 1 : 0.97)
    }

    @ViewBuilder
    private func widgetAppearancePickerContent(for style: LockScreenWidgetAppearanceStyle, isSelected: Bool) -> some View {
        LockScreenWidgetAppearancePickerPreview(style: style)
        .scaleEffect(isSelected ? 1 : 0.97)
    }
}

private struct LockScreenWidgetAppearancePickerPreview: View {
    let style: LockScreenWidgetAppearanceStyle

    private let panelSize = CGSize(width: 380, height: 228)
    private let panelCornerRadius: CGFloat = 34
    private let previewScale: CGFloat = 0.34
    private let progress: CGFloat = 81.0 / 214.0

    var body: some View {
        ZStack {
            LockScreenWidgetPreviewSurface(style: style, cornerRadius: panelCornerRadius)

            VStack {
                HStack(spacing: 18) {
                    previewArtwork

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .center, spacing: 10) {
                            Text("Midnight Echoes")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white.opacity(0.82))
                                .lineLimit(1)

                            Spacer(minLength: 0)

                            previewEqualizer
                        }

                        Text("Debug Ensemble")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer()

                HStack(spacing: 10) {
                    Text("1:21")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))

                    previewProgressBar

                    Text("3:34")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                ZStack {
                    HStack(spacing: 28) {
                        previewControlImage(systemName: "backward.fill", fontSize: 24, controlSize: 46, opacity: 0.9)
                        previewControlImage(systemName: "pause.fill", fontSize: 34, controlSize: 46, opacity: 0.9)
                        previewControlImage(systemName: "forward.fill", fontSize: 24, controlSize: 46, opacity: 0.9)
                    }

                    HStack {
                        previewControlImage(systemName: "star", fontSize: 22, controlSize: 46, opacity: 0.5)
                        Spacer()
                        previewControlImage(systemName: "airplayaudio", fontSize: 22, controlSize: 46, opacity: 0.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(22)
        }
        .frame(width: panelSize.width, height: panelSize.height)
        .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                .stroke(previewStrokeColor, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 26, x: 0, y: 14)
        .scaleEffect(previewScale)
        .frame(width: scaledPanelWidth, height: scaledPanelHeight)
        .environment(\.colorScheme, .dark)
        .allowsHitTesting(false)
    }

    private var previewArtwork: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.48, blue: 0.20),
                        Color(red: 1.00, green: 0.79, blue: 0.29)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 70, height: 70)
            .overlay(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [
                        .black.opacity(0.28),
                        .clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
    }

    private var previewEqualizer: some View {
        HStack(alignment: .center, spacing: 3.0) {
            ForEach([13.0, 17.0, 21.0, 16.0, 12.0], id: \.self) { barHeight in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.72),
                                .white.opacity(0.38)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3.0, height: barHeight)
            }
        }
        .frame(height: 21, alignment: .center)
        .opacity(0.92)
    }

    private var previewProgressBar: some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width
            let trackHeight: CGFloat = 8

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.15))
                    .frame(height: trackHeight)

                Capsule(style: .continuous)
                    .fill(.white.opacity(0.5))
                    .frame(width: trackWidth * progress, height: trackHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 20)
    }

    private func previewControlImage(systemName: String, fontSize: CGFloat, controlSize: CGFloat, opacity: CGFloat) -> some View {
        Image(systemName: systemName)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(.white.opacity(opacity))
            .frame(width: controlSize, height: controlSize)
    }

    private var scaledPanelWidth: CGFloat {
        panelSize.width * previewScale
    }

    private var scaledPanelHeight: CGFloat {
        panelSize.height * previewScale
    }

    private var previewStrokeColor: Color {
        switch style {
        case .ultraThinMaterial:
            return .white.opacity(0.15)
        case .ultraThickMaterial:
            return .white.opacity(0.18)
        case .liquidGlass:
            return .white.opacity(0.12)
        }
    }
}

private struct LockScreenWidgetPreviewSurface: View {
    let style: LockScreenWidgetAppearanceStyle
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        switch style {
        case .ultraThinMaterial:
            shape
                .fill(.ultraThinMaterial)
                .overlay {
                    shape.stroke(.white.opacity(0.14), lineWidth: 1)
                }

        case .ultraThickMaterial:
            shape
                .fill(.ultraThickMaterial)
                .overlay {
                    shape.stroke(.white.opacity(0.16), lineWidth: 1)
                }

        case .liquidGlass:
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: shape)
                    .overlay {
                        shape.stroke(.white.opacity(0.12), lineWidth: 1)
                    }
            } else {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay {
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.14),
                                        .white.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        shape.stroke(.white.opacity(0.12), lineWidth: 1)
                    }
            }
        }
    }
}
