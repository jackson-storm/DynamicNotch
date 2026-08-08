import SwiftUI

struct StopwatchSetupNotchView: View {
    @ObservedObject var stopwatchViewModel: StopwatchViewModel
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)

            Text(stopwatchViewModel.formattedElapsed())
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .foregroundStyle(.orange)
                .monospacedDigit()
                .contentTransition(.numericText())

            controls
        }
        .padding(.horizontal, isDynamicIsland ? 8 : 16)
        .padding(.bottom, 2)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button("Reset") {
                stopwatchViewModel.reset()
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .gray.opacity(0.2)))

            Button {
                if stopwatchViewModel.state == .running {
                    stopwatchViewModel.pause()
                } else {
                    stopwatchViewModel.startOrResume()
                }
            } label: {
                Image(systemName: stopwatchViewModel.state == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(stopwatchViewModel.state == .running ? .orange : .green)
            }
            .buttonStyle(PrimaryButtonStyle(height: 35, backgroundColor: .white.opacity(0.12)))
        }
    }
}
