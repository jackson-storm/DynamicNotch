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
        SettingsCard(title: "settings.timer.card.activity") {
            SettingsToggleRow(
                title: "settings.timer.activity.title",
                description: "settings.timer.activity.desc",
                systemImage: "timer",
                color: .orange,
                isOn: $mediaSettings.isTimerLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.timer"
            )
        }
    }
}

