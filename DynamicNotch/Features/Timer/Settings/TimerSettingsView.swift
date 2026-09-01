import SwiftUI

struct TimerSettingsView: View {
    @ObservedObject var mediaSettings: MediaAndFilesSettingsStore
    @ObservedObject var appearanceSettings: ApplicationSettingsStore

    var body: some View {
        SettingsPageScrollView {
            timerActivityCard
            soundCard
        }
    }

    private var timerActivityCard: some View {
        SettingsCard(title: "settings.timer.card.activity") {
            SettingsToggleRow(
                title: "settings.timer.activity.title",
                description: "settings.timer.activity.desc",
                systemImage: "timer",
                color: .orange,
                isOn: $mediaSettings.isTimerLiveActivityEnabled,
                accessibilityIdentifier: "settings.activities.live.timer"
            )

            Divider().opacity(0.6)

            SettingsStrokeToggleRow(
                title: "settings.notch.defaultStrokeColor.title",
                description: "settings.notch.defaultStrokeColor.desc",
                isOn: $mediaSettings.isTimerDefaultStrokeEnabled,
                accessibilityIdentifier: "settings.activities.live.timer.defaultStroke"
            )
        }
    }

    private var soundCard: some View {
        SettingsCard(title: "settings.timer.card.sound") {
            SettingsToggleRow(
                title: "settings.timer.sound.title",
                description: "settings.timer.sound.desc",
                systemImage: "speaker.wave.2.fill",
                color: .red,
                isOn: $mediaSettings.isTimerSoundEnabled,
                accessibilityIdentifier: "settings.activities.timer.soundEnabled"
            )

            Divider().opacity(0.6)

            SettingsMenuRow(
                title: "settings.timer.soundType.title",
                description: "settings.timer.soundType.desc",
                options: TimerSound.allCases,
                optionTitle: { LocalizedStringKey($0.displayName) },
                accessibilityIdentifier: "settings.activities.timer.soundType",
                selection: Binding(
                    get: { mediaSettings.timerSound },
                    set: { newSound in
                        mediaSettings.timerSound = newSound
                        TimerSoundPlayer.shared.play(
                            sound: newSound,
                            isSoundEnabled: mediaSettings.isTimerSoundEnabled,
                            loop: false
                        )
                    }
                ),
                leadingAccessory: {
                    Button {
                        TimerSoundPlayer.shared.play(
                            sound: mediaSettings.timerSound,
                            isSoundEnabled: mediaSettings.isTimerSoundEnabled,
                            loop: false
                        )
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            )
            .disabled(!mediaSettings.isTimerSoundEnabled)
            .opacity(mediaSettings.isTimerSoundEnabled ? 1.0 : 0.5)
        }
    }
}


