import SwiftUI

struct LocalTimerCompactIndicatorView: View {
    @ObservedObject var viewModel: LocalTimerViewModel

    private var lineWidth: CGFloat { 2.5 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: viewModel.state == .paused || viewModel.state == .stopped)) { context in
            let progress = resolvedProgress(at: context.date)
            let angle = Angle.degrees((-Double(progress) * 360) - 90)

            ZStack {
                Circle()
                    .fill(.white.opacity(0.04))

                Circle()
                    .stroke(.white.opacity(0.16), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.orange.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(x: -1, y: 1)

                Circle()
                    .fill(.black.opacity(0.34))
                    .padding(lineWidth + 2)

                RoundedRectangle(cornerRadius: 1)
                    .fill(.orange.gradient)
                    .frame(width: 6, height: 2.5)
                    .offset(x: 3.5)
                    .rotationEffect(angle)
            }
            .frame(width: 20, height: 20)
        }
    }

    private func resolvedProgress(at date: Date) -> CGFloat {
        guard viewModel.totalTime > 0 else { return 0 }
        let remaining = viewModel.remainingTime(at: date)
        let rawProgress = CGFloat(1.0 - (remaining / viewModel.totalTime))
        guard remaining > 0 else { return 1 }
        
        if viewModel.state == .paused {
            return max(0, min(rawProgress, 1))
        }

        return max(0.03, min(rawProgress, 1))
    }
}
