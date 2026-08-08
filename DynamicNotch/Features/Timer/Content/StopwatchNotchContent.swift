import SwiftUI

struct StopwatchNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Media.stopwatch.id
    let viewModel: StopwatchViewModel

    var priority: Int { NotchContentRegistry.Media.stopwatch.priority }
    var isExpandable: Bool { true }
    var strokeColor: Color { .orange.opacity(0.3) }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 115, height: baseHeight)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 70, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 150, height: baseHeight + 75)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 190, height: baseHeight + 70)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(StopwatchMinimalNotchView(viewModel: viewModel))
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(StopwatchExpandedNotchView(viewModel: viewModel))
    }
}
