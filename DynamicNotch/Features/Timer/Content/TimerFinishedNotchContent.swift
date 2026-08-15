import SwiftUI

struct TimerFinishedNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.Media.timerFinished.id
    let onDismiss: @MainActor () -> Void
    let onRestart: (@MainActor () -> Void)?

    var priority: Int { NotchContentRegistry.Media.timerFinished.priority }
    var strokeColor: Color { .orange.opacity(0.4) }
    var expandsOnTap: Bool { true }
    var isRestorable: Bool { false }

    init(
        onDismiss: @escaping @MainActor () -> Void = {},
        onRestart: (@MainActor () -> Void)? = nil
    ) {
        self.onDismiss = onDismiss
        self.onRestart = onRestart
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 130, height: baseHeight + 60)
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 185, height: baseHeight + 50)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(TimerFinishedNotchView(onDismiss: onDismiss, onRestart: onRestart))
    }
}

