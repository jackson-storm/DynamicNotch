import SwiftUI

struct FocusSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }

    private var isDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }
    
    var body: some View {
        SettingsPageScrollView {
            focusActivity
            focusDuration
            focusAppearance
        }
    }
    
    private var focusActivity: some View {
        SettingsCard(
            title: "Focus activity",
            subtitle: "Control the persistent Focus state and the short Focus Off notification."
        ) {
            SettingsToggleRow(
                title: "Focus live activity",
                description: "Show a live activity while Focus mode is enabled.",
                systemImage: "moon.fill",
                color: .indigo,
                isOn: $connectivitySettings.isFocusLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.focus"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Focus off activity",
                description: "Show a short notification when Focus mode turns off.",
                systemImage: "moon.stars.fill",
                color: .indigo,
                isOn: $connectivitySettings.isFocusOffTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.focusOff"
            )
        }
    }
    
    private var focusDuration: some View {
        SettingsCard(
            title: "Focus duration",
            subtitle: "Control how long the Focus off notification stays visible."
        ) {
            SettingsSliderRow(
                title: "Focus off duration",
                description: "Choose how long the Focus off notification stays visible.",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.focusOff.duration",
                value: Binding(
                    get: { Double(connectivitySettings.focusOffTemporaryActivityDuration) },
                    set: { connectivitySettings.focusOffTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!connectivitySettings.isFocusOffTemporaryActivityEnabled)
            .opacity(connectivitySettings.isFocusOffTemporaryActivityEnabled ? 1 : 0.5)
        }
    }
    
    private var focusAppearance: some View {
        SettingsCard(
            title: "Focus appearance",
            subtitle: "Choose whether Focus uses the current labels or a cleaner icon-only look."
        ) {
            CustomPicker(
                selection: $connectivitySettings.focusAppearanceStyle,
                options: Array(FocusAppearanceStyle.allCases),
                title: { $0.title },
                headerTitle: "Focus style",
                headerDescription: "Choose whether Focus shows the On and Off labels or only the moon icon.",
                itemHeight: 72,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                focusStylePickerContent(for: style, isSelected: isSelected)
            }

            Divider().opacity(0.6)

            SettingsStrokeToggleRow(
                title: "Default stroke",
                description: "Use the standard white notch stroke instead of the Focus accent stroke.",
                isOn: $connectivitySettings.isFocusDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.focus.defaultStroke"
            )
            .disabled(isDefaultStrokeLocked)
            .opacity(isDefaultStrokeLocked ? 0.5 : 1)
        }
    }
    
    @ViewBuilder
    private func focusStylePickerContent(for style: FocusAppearanceStyle, isSelected: Bool) -> some View {
        ZStack {
            Capsule()
                .fill(.black)
                .overlay {
                    Capsule()
                        .stroke(focusPreviewStrokeColor, lineWidth: 1)
                }
            
            HStack(spacing: 0) {
                if style == .iconsOnly {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.indigo)
                    
                    Spacer()
                    
                } else {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.indigo)
                    
                    Spacer()
                    
                    Text(verbatim: "On")
                        .foregroundStyle(.indigo.opacity(0.8))
                }
            }
            .padding(.leading, 7)
            .padding(.trailing, 10)
        }
        .frame(width: 160, height: 30)
        .environment(\.colorScheme, .dark)
        .scaleEffect(isSelected ? 1 : 0.97)
    }
    
    private var focusPreviewStrokeColor: Color {
        guard appearanceSettings.isShowNotchStrokeEnabled else {
            return .clear
        }

        if appearanceSettings.isDefaultActivityStrokeEnabled || connectivitySettings.isFocusDefaultStrokeEnabled {
            return .white.opacity(0.2)
        }

        return .indigo.opacity(0.3)
    }
}
