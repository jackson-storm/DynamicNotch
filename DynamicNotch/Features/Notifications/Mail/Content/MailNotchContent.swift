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
    
    private var hasSummary: Bool {
        guard let summary = message.summary else { return false }

        return !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func size(baseWidth: CGFloat, baseHeight: CGFloat) -> CGSize {
        let extraHeight: CGFloat = hasSummary ? 85 : 65

        return .init(
            width: baseWidth + Self.extraWidth,
            height: baseHeight + extraHeight
        )
    }

    @MainActor
    func makeView() -> AnyView {
        AnyView(
            MailNotificationView(message: message)
        )
    }
}
