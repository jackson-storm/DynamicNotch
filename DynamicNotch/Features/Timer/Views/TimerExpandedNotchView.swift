import SwiftUI

struct TimerExpandedNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var timerViewModel: TimerViewModel

    private var resolvedSnapshot: ClockTimerSnapshot {
        timerViewModel.snapshot ?? ClockTimerSnapshot(
            identifier: "debug.clock.timer",
            title: "Timer",
            duration: 60,
            endDate: .now.addingTimeInterval(60),
            isPaused: false,
            pausedRemaining: nil,
            fingerprint: "debug.clock.timer"
        )
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(snapshot: resolvedSnapshot, date: context.date)
        }
    }

    private func content(snapshot: ClockTimerSnapshot, date: Date) -> some View {
        let remainingTime = snapshot.remainingTime(at: date)
        let progress = snapshot.progress(at: date)

        return VStack(alignment: .leading, spacing: 16) {
            Spacer()

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: snapshot.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)

                    Text(verbatim: snapshot.isPaused ? "Clock timer is paused" : "Clock timer is running")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer(minLength: 12)

                Text(verbatim: snapshot.isPaused ? "Paused" : formattedClockTime(snapshot.endDate))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.85))
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    TimerCountdownText(snapshot: snapshot)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                        .monospacedDigit()

                    Text(verbatim: snapshot.isPaused ? "paused" : "remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.12))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .orange.opacity(0.45),
                                        .orange
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(16, proxy.size.width * progress))
                    }
                }
                .frame(height: 9)
            }

            HStack(spacing: 12) {
                infoCard(
                    title: "Duration",
                    value: formattedDuration(snapshot.duration)
                )

                infoCard(
                    title: "Ends",
                    value: snapshot.isPaused ? "Paused" : formattedClockTime(snapshot.endDate)
                )

                infoCard(
                    title: "Left",
                    value: formattedDuration(remainingTime)
                )
            }
        }
        .padding(.horizontal, 42.scaled(by: scale))
        .padding(.top, 24.scaled(by: scale))
        .padding(.bottom, 20.scaled(by: scale))
    }

    @ViewBuilder
    private func infoCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.42))

            Text(verbatim: value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func formattedClockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
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
