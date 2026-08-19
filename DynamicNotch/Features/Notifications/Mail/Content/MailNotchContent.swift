import SwiftUI

struct MailNotchContent: NotchContentProtocol, DynamicIslandCustomizable {
    let message: MailMessage
    let onOpen: @MainActor () -> Void
    
    static let extraWidth: CGFloat = 160

    var id: String { "mail.message.\(message.rowID)" }
    var priority: Int { NotchContentRegistry.Notifications.mail.priority }
    var windowLink: (@MainActor () -> Void)? { onOpen }

    private var hasSummary: Bool {
        guard let summary = message.summary else { return false }
        return !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func cornerRadius(baseRadius: CGFloat) -> (top: CGFloat, bottom: CGFloat) {
        (top: 20, bottom: 38)
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraHeight: CGFloat = hasSummary ? 85 : 65
        
        return .init(
            width: baseWidth + Self.extraWidth,
            height: baseHeight + extraHeight
        )
    }

    func dynamicIslandSize(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraHeight: CGFloat = hasSummary ? 70 : 50
        
        return .init(
            width: baseWidth + (hasSummary ? 190 : 160),
            height: baseHeight + extraHeight
        )
    }

    func dynamicIslandCornerRadius(baseHeight: CGFloat) -> CGFloat {
        32
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            MailNotificationView(message: message)
        )
    }
}
