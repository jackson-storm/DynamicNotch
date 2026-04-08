import SwiftUI

struct FocusSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            focusActivity
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
}
