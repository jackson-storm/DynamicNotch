import SwiftUI

struct FocusSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }

    var body: some View {
        SettingsPageScrollView {
            focusActivity
            focusDuration
            focusAppearance
        }
    }
    
    private var focusActivity: some View {
        SettingsCard(title: "settings.focus.card.activity") {
            SettingsToggleRow(
                title: "settings.focus.liveActivity.title",
                description: "settings.focus.liveActivity.desc",
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
                title: "settings.focus.offActivity.title",
                description: "settings.focus.offActivity.desc",
                systemImage: "moon.stars.fill",
                color: .indigo,
                isOn: $connectivitySettings.isFocusOffTemporaryActivityEnabled,
                accessibilityIdentifier: "settings.activities.temporary.focusOff"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsToggleRow(
                title: "settings.focus.autoHide.title",
                description: "settings.focus.autoHide.desc",
                systemImage: "moon.zzz.fill",
                color: .red,
                isOn: $connectivitySettings.isFocusOnAutoHideEnabled,
                accessibilityIdentifier: "settings.activities.live.focus.autoHide"
            )
            .disabled(!connectivitySettings.isFocusLiveActivityEnabled)
            .opacity(connectivitySettings.isFocusLiveActivityEnabled ? 1 : 0.5)
        }
    }
    
    private var focusDuration: some View {
        SettingsCard(title: "settings.focus.card.duration") {
            SettingsSliderRow(
                title: "settings.focus.onDuration.title",
                description: "settings.focus.onDuration.desc",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.activities.temporary.focusOn.duration",
                value: Binding(
                    get: { Double(connectivitySettings.focusOnTemporaryActivityDuration) },
                    set: { connectivitySettings.focusOnTemporaryActivityDuration = Int($0.rounded()) }
                )
            )
            .disabled(!connectivitySettings.isFocusOnAutoHideEnabled || !connectivitySettings.isFocusLiveActivityEnabled)
            .opacity(connectivitySettings.isFocusOnAutoHideEnabled && connectivitySettings.isFocusLiveActivityEnabled ? 1 : 0.5)

            Divider().opacity(0.6)

            SettingsSliderRow(
                title: "settings.focus.offDuration.title",
                description: "settings.focus.offDuration.desc",
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
        SettingsCard(title: "settings.focus.card.appearance") {
            CustomPicker(
                selection: $connectivitySettings.focusAppearanceStyle,
                options: Array(FocusAppearanceStyle.allCases),
                title: { $0.title },
                headerTitle: "settings.focus.style.headerTitle",
                headerDescription: "settings.focus.style.headerDesc",
                itemHeight: 72,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                focusStylePickerContent(for: style, isSelected: isSelected)
            }
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

        if appearanceSettings.isDefaultActivityStrokeEnabled {
            return .white.opacity(0.2)
        }

        return .indigo.opacity(0.3)
    }
}
