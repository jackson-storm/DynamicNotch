import SwiftUI

struct FocusSettingsView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Focus mode",
                subtitle: "Separate controls for the long-lived active state and the quick dismissal state."
            ) {
                VStack {
                    SettingsToggleRow(
                        title: "Focus live activity",
                        description: "Show a live indicator when Focus mode turns on.",
                        systemImage: "moon.fill",
                        color: .indigo,
                        isOn: $generalSettingsViewModel.isFocusLiveActivityEnabled,
                        accessibilityIdentifier: "settings.activities.live.focus"
                    )

                    Divider()

                    SettingsToggleRow(
                        title: "Focus off activity",
                        description: "Show a quick state change message when Focus mode is disabled.",
                        systemImage: "moon.stars.fill",
                        color: .indigo,
                        isOn: $generalSettingsViewModel.isFocusOffTemporaryActivityEnabled,
                        accessibilityIdentifier: "settings.activities.temporary.focusOff"
                    )
                }
            }
        }
    }
}
