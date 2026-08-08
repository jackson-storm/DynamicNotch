import SwiftUI

struct PomodoroMinimalNotchView: View {
    @Environment(\.notchScale) private var notchScale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var viewModel: PomodoroViewModel

    var body: some View {
        HStack {
            Image(systemName: viewModel.phase == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                .font(.system(size: isDynamicIsland ? 16 : 20, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Text(viewModel.formattedRemainingTime)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(viewModel.phase == .focus ? .red : .green)
                .monospacedDigit()
        }
        .padding(.leading, isDynamicIsland ? 6.scaled(by: notchScale) : 14.scaled(by: notchScale))
        .padding(.trailing, isDynamicIsland ? 6.scaled(by: notchScale) : 14.scaled(by: notchScale))
    }
}
