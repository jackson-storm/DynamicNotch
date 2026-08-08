import SwiftUI

struct StopwatchMinimalNotchView: View {
    @ObservedObject var viewModel: StopwatchViewModel
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland

    var body: some View {
        HStack {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: isDynamicIsland ? 16 : 20, weight: .semibold))
                .foregroundStyle(.orange)

            Spacer()

            Text(viewModel.formattedElapsed(includesFraction: false))
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.orange)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.leading, isDynamicIsland ? 6.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 6.scaled(by: scale) : 14.scaled(by: scale))
    }
}
