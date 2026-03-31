import SwiftUI

struct FocusSettingsView: View {
    @ObservedObject var connectivitySettings: ConnectivitySettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            focusActivity
            focusAppearance
        }
    }
    
    private var focusActivity: some View {
        SettingsCard(
            title: "Focus activity",
            subtitle: "Control the persistent Focus state and the short Focus Off notification."
        ) {
            VStack {
                SettingsToggleRow(
                    title: "Focus live activity",
                    description: "Show a live activity while Focus mode is enabled.",
                    systemImage: "moon.fill",
                    color: .indigo,
                    isOn: $connectivitySettings.isFocusLiveActivityEnabled,
                    accessibilityIdentifier: "settings.activities.live.focus"
                )

                Divider()

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
    
    private var focusAppearance: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "Focus appearance",
                subtitle: "Preview the Focus notch and adjust its accent stroke."
            ) {
                NotchPreview(
                    width: 260,
                    height: 38,
                    showsStroke: appearanceSettings.isShowNotchStrokeEnabled,
                    strokeColor: connectivitySettings.isFocusDefaultStrokeEnabled ?
                        .white.opacity(0.2) :
                            .indigo.opacity(0.3),
                    strokeWidth: CGFloat(appearanceSettings.notchStrokeWidth)
                ) {
                    FocusPreviewNotchView()
                }
                
                SettingsToggleRow(
                    title: "Use default stroke color",
                    description: "Use the default notch stroke color instead of the Focus accent colors.",
                    systemImage: "paintbrush.pointed.fill",
                    color: .indigo,
                    isOn: $connectivitySettings.isFocusDefaultStrokeEnabled,
                    accessibilityIdentifier: "settings.activities.focus.defaultStroke"
                )
            }
        }
    }
}
