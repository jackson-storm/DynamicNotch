import SwiftUI

struct NotificationsHomePageNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let id = NotchContentRegistry.HomePage.active.id
    let notificationCenterViewModel: NotificationCenterViewModel

    var priority: Int { NotchContentRegistry.HomePage.active.priority }
    var isExpandable: Bool { true }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth, height: baseHeight)
    }

    func expandedCornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 24, bottom: 38)
    }

    func expandedSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 170, height: baseHeight + 130)
    }

    func expandedDynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + 200, height: baseHeight + 130)
    }

    func expandedDynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        baseHeight * 0.2
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}
