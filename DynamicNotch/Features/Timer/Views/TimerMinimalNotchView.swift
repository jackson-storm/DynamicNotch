import SwiftUI

struct TimerMinimalNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var timerViewModel: TimerViewModel

    private var snapshot: ClockTimerSnapshot? {
        timerViewModel.snapshot
    }

    var body: some View {
        HStack(spacing: 10) {
            TimerCompactIndicatorView(
                snapshot: snapshot ?? ClockTimerSnapshot(
                    identifier: "debug.clock.timer",
                    title: "Timer",
                    duration: 0,
                    endDate: .now,
                    isPaused: false,
                    pausedRemaining: nil,
                    fingerprint: "debug.clock.timer.idle"
                )
            )

            Spacer(minLength: 0)

            TimerCountdownText(
                timerViewModel: timerViewModel,
                snapshot: snapshot ?? ClockTimerSnapshot(
                    identifier: "debug.clock.timer",
                    title: "Timer",
                    duration: 0,
                    endDate: .now,
                    isPaused: false,
                    pausedRemaining: nil,
                    fingerprint: "debug.clock.timer.idle"
                )
            )
            .foregroundStyle(.orange)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
