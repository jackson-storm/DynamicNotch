import SwiftUI

struct TimerExpandedNotchView: View {
    @ObservedObject var timerViewModel: TimerViewModel
    @State private var isControlActionRunning = false

    private var resolvedSnapshot: ClockTimerSnapshot {
        timerViewModel.snapshot ?? ClockTimerSnapshot(
            identifier: "debug.clock.timer",
            title: "Timer",
            duration: 0,
            endDate: .now.addingTimeInterval(0),
            isPaused: false,
            pausedRemaining: nil,
            fingerprint: "debug.clock.timer"
        )
    }

    private var pauseButtonSymbol: String {
        resolvedSnapshot.isPaused ? "play.fill" : "pause.fill"
    }

    var body: some View {
        VStack {
            Spacer()

            HStack {
                leftContent
                Spacer()
                rightContent
            }
        }
        .padding(.horizontal, 32)
        .padding(.trailing, 3)
        .padding(.bottom, 12)
    }

    private var leftContent: some View {
        HStack {
            Button {
                guard !isControlActionRunning else { return }

                Task { @MainActor in
                    isControlActionRunning = true
                    defer { isControlActionRunning = false }
                    _ = await timerViewModel.togglePauseResume()
                }
            } label: {
                Image(systemName: pauseButtonSymbol)
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .orange.opacity(0.3)))
            .disabled(isControlActionRunning)

            Button {
                guard !isControlActionRunning else { return }

                Task { @MainActor in
                    isControlActionRunning = true
                    defer { isControlActionRunning = false }
                    _ = await timerViewModel.stopTimer()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .bold()
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(PrimaryButtonStyle(width: 45, height: 45, backgroundColor: .gray.opacity(0.3)))
            .disabled(isControlActionRunning)
        }
    }

    private var rightContent: some View {
        HStack {
            Text("Timer")
                .font(.system(size: 14))
                .foregroundStyle(Color.orange.opacity(0.8))
                .offset(y: 8)

            TimelineView(.animation(minimumInterval: 0.25, paused: resolvedSnapshot.isPaused)) { context in
                Text(formattedDuration(resolvedSnapshot.remainingTime(at: context.date)))
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.orange)
                    .contentTransition(.numericText())
            }
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let roundedSeconds = max(0, Int(duration.rounded()))
        let hours = roundedSeconds / 3600
        let minutes = (roundedSeconds % 3600) / 60
        let seconds = roundedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
