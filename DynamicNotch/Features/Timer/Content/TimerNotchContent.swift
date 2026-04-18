import SwiftUI

struct TimerNotchContent: NotchContentProtocol {
    static let activityID = "clock.timer"

    let id = Self.activityID
    let timerViewModel: TimerViewModel

    var priority: Int { 86 }
    var isExpandable: Bool { true }
    var strokeColor: Color { .orange.opacity(0.3) }
    var offsetXTransition: CGFloat { -55 }
    var expandedOffsetXTransition: CGFloat { -90 }
    var expandedOffsetYTransition: CGFloat { -72 }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 180, height: baseHeight)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 170, height: baseHeight + 70)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(TimerMinimalNotchView(timerViewModel: timerViewModel))
    }

    @MainActor
    func makeExpandedView() -> AnyView {
        AnyView(TimerExpandedNotchView(timerViewModel: timerViewModel))
    }
}
