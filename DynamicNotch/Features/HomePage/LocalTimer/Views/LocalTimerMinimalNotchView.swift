import SwiftUI

struct LocalTimerMinimalNotchView: View {
    @Environment(\.notchScale) private var scale
    @ObservedObject var viewModel: LocalTimerViewModel

    var body: some View {
        HStack(spacing: 10) {
            LocalTimerCompactIndicatorView(viewModel: viewModel)
            Spacer()
            LocalTimerCountdownText(viewModel: viewModel)
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14.scaled(by: scale))
    }
}
