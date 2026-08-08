import SwiftUI

struct PomodoroMinimalNotchView: View {
    @Environment(\.notchScale) private var notchScale
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    @ObservedObject var viewModel: PomodoroViewModel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.phase.symbolName)
                .font(.system(size: isDynamicIsland ? 15 : 18, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: isDynamicIsland ? 18 : 22, alignment: .leading)

            Spacer(minLength: 8)

            Text(viewModel.formattedRemainingTime)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(accentColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .layoutPriority(1)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var accentColor: Color {
        viewModel.phase == .focus ? .red : .green
    }

    private var horizontalPadding: CGFloat {
        (isDynamicIsland ? 6 : 12).scaled(by: notchScale)
    }
}
