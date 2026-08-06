import SwiftUI

struct MailNotchContent: NotchContentProtocol {

    let message: MailMessage
    let onOpen: @MainActor () -> Void

    var id: String {
        "mail.message.\(message.rowID)"
    }

    var windowLink: (@MainActor () -> Void)? {
        onOpen
    }

    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        CGSize(width: 330, height: 96)
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            MailNotificationView(message: message)
        )
    }
}
