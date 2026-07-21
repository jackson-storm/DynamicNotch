import SwiftUI

struct ScreenRecordingSettingsView: View {
    @ObservedObject var settings: ScreenRecordingSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            screenRecordingActivity
        }
    }

    private var screenRecordingActivity: some View {
        SettingsCard(title: "Screen Recording activity") {
            SettingsToggleRow(
                title: "Screen Recording live activity",
                description: "Show a red recording indicator in the notch while screen capture is active.",
                systemImage: "record.circle.fill",
                color: .red,
                isOn: $settings.isScreenRecordingLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.screenRecording"
            )
        }
    }
}

