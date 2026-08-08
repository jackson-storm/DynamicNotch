import SwiftUI

struct PomodoroNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Media.pomodoro.id
    let viewModel: PomodoroViewModel
    let notchViewModel: NotchViewModel
    let stopwatchViewModel: StopwatchViewModel?

    var priority: Int { NotchContentRegistry.Media.pomodoro.priority }
    var isExpandable: Bool { true }
    var strokeColor: Color { .red.opacity(0.3) }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 120, height: baseHeight)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 110, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 190, height: baseHeight + 165)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 260, height: baseHeight + 165)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 38)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            PomodoroMinimalNotchView(
                viewModel: viewModel,
                notchViewModel: notchViewModel
            )
        )
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            PomodoroExpandedNotchView(
                viewModel: viewModel,
                notchViewModel: notchViewModel,
                stopwatchViewModel: stopwatchViewModel
            )
        )
    }
}
