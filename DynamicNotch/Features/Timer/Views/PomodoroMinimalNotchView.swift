import SwiftUI

struct PomodoroMinimalNotchView: View {
    @Environment(\.notchScale) private var notchScale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var viewModel: PomodoroViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.phase == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                .font(.system(size: isDynamicIsland ? 16 : 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: isDynamicIsland ? 18 : 22)

            Spacer()

            Text(viewModel.formattedRemainingTime)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(viewModel.phase == .focus ? .red : .green)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, isDynamicIsland ? 6.scaled(by: notchScale) : 14.scaled(by: notchScale))
        .padding(.trailing, isDynamicIsland ? 6.scaled(by: notchScale) : 14.scaled(by: notchScale))
        .clipped()
    }
}
