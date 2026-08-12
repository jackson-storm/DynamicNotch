import SwiftUI

struct MailNotchContent: NotchContentProtocol {
    
    static let extraWidth: CGFloat = 160

    let message: MailMessage
    let onOpen: @MainActor () -> Void

    var id: String {
        "mail.message.\(message.rowID)"
    }

    var windowLink: (@MainActor () -> Void)? {
        onOpen
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        .init(width: baseWidth + Self.extraWidth, height: baseHeight + 85)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            MailNotificationView(message: message)
        )
    }
}
