import Foundation

struct MailMessage: Equatable {
    let rowID: Int64
    let messageIDHeader: String
    let sender: String
    let subject: String
    let summary: String?
    let receivedDate: Date
}

#if DEBUG
extension MailMessage {
    static let debugPreview = MailMessage(
        rowID: -1,
        messageIDHeader: "<debug@mail.preview>",
        sender: "debug@mail.preview",
        subject: "Test email",
        summary: "This is a test text of the letter to customize the appearance of the DynamicNotch notification.",
        receivedDate: Date()
    )
}
#endif
