import SwiftUI

struct LocalTimerMinimalNotchView: View {
    @Environment(\.notchScale) private var scale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var viewModel: LocalTimerViewModel

    var body: some View {
        HStack(spacing: 10) {
            LocalTimerCompactIndicatorView(viewModel: viewModel)
            Spacer()
            LocalTimerCountdownText(viewModel: viewModel)
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 10)
        .padding(.leading, isDynamicIsland ? 5.scaled(by: scale) : 14.scaled(by: scale))
        .padding(.trailing, isDynamicIsland ? 8.scaled(by: scale) : 14.scaled(by: scale))
    }
}
