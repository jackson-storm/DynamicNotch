import SwiftUI

struct PomodoroSettingsView: View {
    @AppStorage("pomodoro.rebuilt.focusMinutes") private var focusMinutes = 25
    @AppStorage("pomodoro.rebuilt.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.rebuilt.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.rebuilt.soundsEnabled") private var soundsEnabled = true

    @ObservedObject private var viewModel = PomodoroViewModel.shared

    var body: some View {
        SettingsPageScrollView {
            durationsCard
            soundCard
            defaultsCard
        }
        .onAppear(perform: applyAllSettings)
        .onChange(of: focusMinutes) { _, value in
            viewModel.updateDuration(minutes: value, for: .focus)
        }
        .onChange(of: shortBreakMinutes) { _, value in
            viewModel.updateDuration(minutes: value, for: .shortBreak)
        }
        .onChange(of: longBreakMinutes) { _, value in
            viewModel.updateDuration(minutes: value, for: .longBreak)
        }
        .onChange(of: soundsEnabled) { _, value in
            viewModel.setSoundsEnabled(value)
        }
    }

    private var durationsCard: some View {
        SettingsCard(title: "Session durations") {
            PomodoroDurationSettingsRow(
                title: "Focus",
                description: "Length of each focus session.",
                systemImage: "brain.head.profile",
                color: .red,
                minutes: $focusMinutes
            )

            Divider().opacity(0.6)

            PomodoroDurationSettingsRow(
                title: "Short break",
                description: "Break after a normal focus session.",
                systemImage: "cup.and.saucer.fill",
                color: .green,
                minutes: $shortBreakMinutes
            )

            Divider().opacity(0.6)

            PomodoroDurationSettingsRow(
                title: "Long break",
                description: "Break after every fourth completed focus session.",
                systemImage: "bed.double.fill",
                color: .blue,
                minutes: $longBreakMinutes
            )
        }
    }

    private var soundCard: some View {
        SettingsCard(title: "Sounds") {
            SettingsToggleRow(
                title: "Pomodoro sounds",
                description: "Play the wind-up, ticking, and completion sounds.",
                systemImage: "speaker.wave.2.fill",
                color: .orange,
                isOn: $soundsEnabled,
                accessibilityIdentifier: "settings.pomodoro.sounds"
            )
        }
    }

    private var defaultsCard: some View {
        SettingsCard {
            SettingsButtonRow(
                title: "Restore Pomodoro defaults",
                description: "Set focus to 25 minutes, short break to 5, long break to 15, and enable sounds.",
                systemImage: "arrow.counterclockwise",
                color: .gray,
                buttonTitle: "Restore",
                accessibilityIdentifier: "settings.pomodoro.restoreDefaults",
                action: restoreDefaults
            )
        }
    }

    private func applyAllSettings() {
        viewModel.updateDuration(minutes: focusMinutes, for: .focus)
        viewModel.updateDuration(minutes: shortBreakMinutes, for: .shortBreak)
        viewModel.updateDuration(minutes: longBreakMinutes, for: .longBreak)
        viewModel.setSoundsEnabled(soundsEnabled)
    }

    private func restoreDefaults() {
        focusMinutes = 25
        shortBreakMinutes = 5
        longBreakMinutes = 15
        soundsEnabled = true
        applyAllSettings()
    }
}

private struct PomodoroDurationSettingsRow: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let systemImage: String
    let color: Color
    @Binding var minutes: Int

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            SettingsIconBadge(
                systemImage: systemImage,
                tint: AnyShapeStyle(color.gradient),
                size: 30,
                iconSize: 14,
                cornerRadius: 9
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Stepper(value: $minutes, in: 1...120) {
                Text("\(minutes) min")
                    .monospacedDigit()
                    .frame(minWidth: 50, alignment: .trailing)
            }
            .fixedSize()
        }
    }
}
