import Foundation

enum AppNotificationItem: Identifiable, Equatable, Sendable {
    case message(MessagesMessage)
    case mail(MailMessage)

    var id: String {
        switch self {
        case .message(let message):
            return "msg-\(message.id)"
        case .mail(let mail):
            return "mail-\(mail.rowID)"
        }
    }

    var receivedDate: Date {
        switch self {
        case .message(let message):
            return message.receivedDate
        case .mail(let mail):
            return mail.receivedDate
        }
    }
}
