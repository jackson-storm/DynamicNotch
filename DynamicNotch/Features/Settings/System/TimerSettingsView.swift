import SwiftUI

struct TimerSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

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
        }
    }
}

