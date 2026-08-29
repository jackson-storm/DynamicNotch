import SwiftUI

struct MessagesNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let message: MessagesMessage
    let onOpen: @MainActor () -> Void

    static let extraWidth: CGFloat = 160

    var id: String { NotchContentRegistry.Notifications.messages.id }
    var priority: Int { NotchContentRegistry.Notifications.messages.priority }
    var windowLink: (@MainActor () -> Void)? { onOpen }

    private var hasText: Bool {
        !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraHeight: CGFloat = hasText ? 80 : 60

        return .init(
            width: baseWidth + Self.extraWidth,
            height: baseHeight + extraHeight
        )
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraHeight: CGFloat = hasText ? 80 : 60

        return .init(
            width: baseWidth + (hasText ? 210 : 180),
            height: baseHeight + extraHeight
        )
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        return baseHeight * 0.3
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            MessagesNotificationView(message: message)
        )
    }
}
