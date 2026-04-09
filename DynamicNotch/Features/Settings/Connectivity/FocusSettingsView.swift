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
}
