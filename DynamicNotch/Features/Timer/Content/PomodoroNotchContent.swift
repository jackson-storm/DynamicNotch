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
        .init(width: baseWidth + 115, height: baseHeight)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 65, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 60, height: baseHeight + 135)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 100, height: baseHeight + 135)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 38)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(PomodoroMinimalNotchView(viewModel: viewModel))
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(
            PomodoroNotchView(
                viewModel: viewModel,
                notchViewModel: notchViewModel,
                stopwatchViewModel: stopwatchViewModel
            )
        )
    }
}
