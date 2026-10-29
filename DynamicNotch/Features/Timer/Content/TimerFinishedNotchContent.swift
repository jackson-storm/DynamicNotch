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

    func compactSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 130, height: baseHeight + 60)
    }
    
    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 250, height: baseHeight + 50)
    }

    func compactCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.5
    }

    @MainActor
    func compactView() -> AnyView {
        AnyView(TimerFinishedNotchView(onDismiss: onDismiss, onRestart: onRestart))
    }
}

