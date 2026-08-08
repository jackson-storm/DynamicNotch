import SwiftUI

struct PomodoroPanelView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    let notchViewModel: NotchViewModel
    let stopwatchViewModel: StopwatchViewModel?

    @AppStorage("pomodoro.rebuilt.focusMinutes") private var focusMinutes = 25
    @AppStorage("pomodoro.rebuilt.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.rebuilt.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.rebuilt.soundsEnabled") private var soundsEnabled = true

    var body: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            header
            remainingTime
            progress
            durationControls
            actionButtons
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear {
            synchronizePreferences()
        }
        .onChange(of: focusMinutes) { _, value in
            viewModel.updateDuration(minutes: value, for: .focus)
        }
        .onChange(of: shortBreakMinutes) { _, value in
            viewModel.updateDuration(minutes: value, for: .shortBreak)
        }
        .onChange(of: longBreakMinutes) { _, value in
            viewModel.updateDuration(minutes: value, for: .longBreak)
        }
        .onChange(of: soundsEnabled) { _, enabled in
            viewModel.setSoundsEnabled(enabled)
        }
        .onChange(of: viewModel.state) { _, state in
            handleStateChange(state)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label(viewModel.phase.title, systemImage: viewModel.phase.symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 6)

            Button {
                soundsEnabled.toggle()
            } label: {
                Image(systemName: soundsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            Text("\(viewModel.completedFocusSessions) sessions")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }

    private var remainingTime: some View {
        Text(viewModel.formattedRemainingTime)
            .font(.system(size: 38, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .monospacedDigit()
            .contentTransition(.numericText())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
    }

    private var progress: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.10))
                Capsule()
                    .fill(accentColor)
                    .frame(width: geometry.size.width * viewModel.progress)
            }
        }
        .frame(height: 4)
        .frame(maxWidth: .infinity)
    }

    private var durationControls: some View {
        HStack(spacing: 10) {
            durationControl(title: "FOCUS", phase: .focus, minutes: $focusMinutes)
            durationControl(title: "SHORT", phase: .shortBreak, minutes: $shortBreakMinutes)
            durationControl(title: "LONG", phase: .longBreak, minutes: $longBreakMinutes)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button("Reset") {
                viewModel.reset()
            }
            .buttonStyle(PrimaryButtonStyle(height: 34, backgroundColor: .gray.opacity(0.22)))

            Button {
                if viewModel.state == .running {
                    viewModel.pause()
                } else {
                    viewModel.startOrResume()
                }
            } label: {
                Image(systemName: viewModel.state == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(viewModel.state == .running ? .orange : .green)
            }
            .buttonStyle(PrimaryButtonStyle(height: 34, backgroundColor: .white.opacity(0.12)))

            Button {
                viewModel.skip()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(PrimaryButtonStyle(height: 34, backgroundColor: .gray.opacity(0.22)))
        }
        .frame(maxWidth: .infinity)
    }

    private func durationControl(
        title: String,
        phase: PomodoroPhase,
        minutes: Binding<Int>
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 3) {
                adjustmentButton(systemName: "minus", enabled: minutes.wrappedValue > 1) {
                    minutes.wrappedValue = max(1, minutes.wrappedValue - 1)
                }

                Text("\(minutes.wrappedValue)m")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(minWidth: 27)

                adjustmentButton(systemName: "plus", enabled: minutes.wrappedValue < 120) {
                    minutes.wrappedValue = min(120, minutes.wrappedValue + 1)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(phase.title) duration")
    }

    private func adjustmentButton(
        systemName: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 8, weight: .bold))
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.white.opacity(enabled ? 0.10 : 0.04), in: Circle())
        .disabled(!enabled)
    }

    private var accentColor: Color {
        viewModel.phase == .focus ? .red : .green
    }

    private func synchronizePreferences() {
        viewModel.updateDuration(minutes: focusMinutes, for: .focus)
        viewModel.updateDuration(minutes: shortBreakMinutes, for: .shortBreak)
        viewModel.updateDuration(minutes: longBreakMinutes, for: .longBreak)
        viewModel.setSoundsEnabled(soundsEnabled)
    }

    private func handleStateChange(_ state: PomodoroTimerState) {
        switch state {
        case .running, .paused:
            if stopwatchViewModel?.state != .stopped {
                stopwatchViewModel?.stop()
            }
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.stopwatch.id))
            notchViewModel.send(
                .showLiveActivity(
                    PomodoroNotchContent(
                        viewModel: viewModel,
                        notchViewModel: notchViewModel,
                        stopwatchViewModel: stopwatchViewModel
                    )
                )
            )
        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.pomodoro.id))
        }
    }
}
