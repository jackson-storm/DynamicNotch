import SwiftUI

struct StopwatchExpandedNotchView: View {
    @ObservedObject var viewModel: StopwatchViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            HStack(spacing: 12) {
                controls
                Spacer()
                elapsedTime
            }
        }
        .padding(.horizontal, isDynamicIsland ? 18 : 28)
        .padding(.bottom, isDynamicIsland ? 13 : 11)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button {
                if viewModel.state == .running {
                    viewModel.pause()
                } else {
                    viewModel.startOrResume()
                }
            } label: {
                Image(systemName: viewModel.state == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.orange)
            }
            .buttonStyle(PrimaryButtonStyle(width: 44, height: 44, backgroundColor: .orange.opacity(0.25)))

            Button {
                viewModel.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .buttonStyle(PrimaryButtonStyle(width: 44, height: 44, backgroundColor: .gray.opacity(0.25)))
        }
    }

    private var elapsedTime: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("Stopwatch")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Text(viewModel.formattedElapsed())
                .font(.system(size: 29, weight: .semibold, design: .rounded))
                .foregroundStyle(.orange)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }
}
