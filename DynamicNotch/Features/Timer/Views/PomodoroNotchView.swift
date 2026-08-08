import SwiftUI

struct PomodoroNotchView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    let notchViewModel: NotchViewModel

    @AppStorage("pomodoro.focusMinutes") private var focusMinutes = 25
    @AppStorage("pomodoro.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.soundsEnabled") private var soundsEnabled = true

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Label(viewModel.phase.title, systemImage: viewModel.phase == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(viewModel.phase == .focus ? .red : .green)

                Spacer()

                Button {
                    soundsEnabled.toggle()
                } label: {
                    Image(systemName: soundsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text("\(viewModel.completedFocusSessions) sessions")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text(viewModel.formattedRemainingTime)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .monospacedDigit()

            ProgressView(value: viewModel.progress)
                .tint(viewModel.phase == .focus ? .red : .green)

            HStack(spacing: 8) {
                durationControl("FOCUS", minutes: $focusMinutes, phase: .focus)
                durationControl("SHORT", minutes: $shortBreakMinutes, phase: .shortBreak)
                durationControl("LONG", minutes: $longBreakMinutes, phase: .longBreak)
            }

            HStack(spacing: 8) {
                Button("Reset") { viewModel.reset() }
                    .buttonStyle(PrimaryButtonStyle(height: 30, backgroundColor: .gray.opacity(0.2)))

                Button {
                    if viewModel.state == .running {
                        viewModel.pause()
                    } else {
                        viewModel.startOrResume()
                    }
                } label: {
                    Image(systemName: viewModel.state == .running ? "pause.fill" : "play.fill")
                        .foregroundStyle(viewModel.state == .running ? .orange : .green)
                }
                .buttonStyle(PrimaryButtonStyle(height: 30, backgroundColor: .white.opacity(0.12)))

                Button { viewModel.skip() } label: {
                    Image(systemName: "forward.end.fill")
                        .foregroundStyle(.white)
                }
                .buttonStyle(PrimaryButtonStyle(height: 30, backgroundColor: .gray.opacity(0.2)))
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            synchronizeDurations()
            viewModel.setSoundsEnabled(soundsEnabled)
        }
        .onChange(of: focusMinutes) { _, value in update(value, phase: .focus) }
        .onChange(of: shortBreakMinutes) { _, value in update(value, phase: .shortBreak) }
        .onChange(of: longBreakMinutes) { _, value in update(value, phase: .longBreak) }
        .onChange(of: soundsEnabled) { _, enabled in
            viewModel.setSoundsEnabled(enabled)
        }
        .onChange(of: viewModel.state) { _, state in
            switch state {
            case .running, .paused:
                notchViewModel.send(
                    .showLiveActivity(
                        PomodoroNotchContent(
                            viewModel: viewModel,
                            notchViewModel: notchViewModel
                        )
                    )
                )
            case .stopped:
                notchViewModel.send(
                    .hideLiveActivity(id: NotchContentRegistry.Media.pomodoro.id)
                )
            }
        }
    }

    private func durationControl(
        _ title: String,
        minutes: Binding<Int>,
        phase: PomodoroPhase
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
            Stepper(value: minutes, in: 1...120) {
                Text("\(minutes.wrappedValue)m")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func synchronizeDurations() {
        update(focusMinutes, phase: .focus)
        update(shortBreakMinutes, phase: .shortBreak)
        update(longBreakMinutes, phase: .longBreak)
    }

    private func update(_ minutes: Int, phase: PomodoroPhase) {
        viewModel.updateDuration(minutes: minutes, for: phase)
    }
}
