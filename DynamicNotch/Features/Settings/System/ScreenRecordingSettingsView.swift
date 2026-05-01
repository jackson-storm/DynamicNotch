import SwiftUI

struct ScreenRecordingSettingsView: View {
    @ObservedObject var settings: ScreenRecordingSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    private var isDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }

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

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsStrokeToggleRow(
                title: "Default stroke",
                description: "Use the standard white notch stroke instead of the red recording stroke.",
                isOn: $settings.isScreenRecordingDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.screenRecording.defaultStroke"
            )
            .disabled(isDefaultStrokeLocked)
            .opacity(isDefaultStrokeLocked ? 0.5 : 1)
        }
    }
}
