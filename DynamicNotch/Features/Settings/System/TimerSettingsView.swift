import SwiftUI

struct TimerSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    private var isDefaultStrokeLocked: Bool {
        appearanceSettings.isDefaultActivityStrokeEnabled
    }

    var body: some View {
        SettingsPageScrollView {
            timerActivity
        }
    }

    private var timerActivity: some View {
        SettingsCard(title: "Timer activity") {
            SettingsToggleRow(
                title: "Timer live activity",
                description: "Show the active Clock timer in the notch.",
                systemImage: "timer",
                color: .orange,
                isOn: $mediaSettings.isTimerLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.timer"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsStrokeToggleRow(
                title: "Default stroke",
                description: "Use the standard white notch stroke instead of the orange timer stroke.",
                isOn: $mediaSettings.isTimerDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.timer.defaultStroke"
            )
            .disabled(isDefaultStrokeLocked)
            .opacity(isDefaultStrokeLocked ? 0.5 : 1)
        }
    }
}
