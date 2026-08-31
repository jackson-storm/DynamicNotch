import Foundation

struct MessagesMessage: Equatable, Identifiable, Sendable {
    let rowID: Int64
    let guid: String
    let sender: MessagesSender
    let service: MessagesService
    let conversation: MessagesConversation?
    let receivedDate: Date
    let parts: [MessagesMessagePart]

    var id: Int64 {
        rowID
    }
}

enum MessagesMessagePart: Equatable, Sendable {
    case text(String)
    case attachment(MessagesAttachment)
}

struct MessagesConversation: Equatable, Sendable {
    let identifier: String?
    let displayName: String?
    let isGroup: Bool
}

enum MessagesService: String, Equatable, Sendable {
    case iMessage = "iMessage"
    case sms = "SMS"
    case unknown

    init(databaseValue: String?) {
        switch databaseValue?.lowercased() {
        case "imessage":
            self = .iMessage
        case "sms":
            self = .sms
        default:
            self = .unknown
        }
    }
}

#if DEBUG
extension MessagesMessage {
    static let debugPreview = debugText

    static let debugText = MessagesMessage(
        rowID: -1,
        guid: "debug-text-message",
        sender: .debugContact,
        service: .iMessage,
        conversation: nil,
        receivedDate: Date(),
        parts: [.text("Hey, are you coming today?")]
    )

    static let debugTextAndImage = MessagesMessage(
        rowID: -2,
        guid: "debug-text-image-message",
        sender: .debugContact,
        service: .iMessage,
        conversation: nil,
        receivedDate: Date(),
        parts: [
            .text("Look at this"),
            .attachment(.debugImage)
        ]
    )

    static let debugAudio = MessagesMessage(
        rowID: -3,
        guid: "debug-audio-message",
        sender: .debugContact,
        service: .iMessage,
        conversation: nil,
        receivedDate: Date(),
        parts: [.attachment(.debugAudio)]
    )

    static let debugMultipleAttachments = MessagesMessage(
        rowID: -4,
        guid: "debug-multiple-attachments-message",
        sender: .debugContact,
        service: .iMessage,
        conversation: nil,
        receivedDate: Date(),
        parts: [
            .attachment(.debugImageAttachment(id: "debug-image-1")),
            .attachment(.debugImageAttachment(id: "debug-image-2")),
            .attachment(.debugImageAttachment(id: "debug-image-3")),
            .attachment(.debugImageAttachment(id: "debug-image-4"))
        ]
    )

    static let debugLongContent = MessagesMessage(
        rowID: -5,
        guid: "debug-long-message",
        sender: .debugContact,
        service: .iMessage,
        conversation: nil,
        receivedDate: Date(),
        parts: [
            .text("This is an intentionally long Messages preview used to verify wrapping, truncation and layout behavior in both the standard MacBook notch and Dynamic Island modes.")
        ]
    )

    static let debugVideo = MessagesMessage(
        rowID: -6,
        guid: "debug-video-message",
        sender: .debugContact,
        service: .iMessage,
        conversation: nil,
        receivedDate: Date(),
        parts: [.attachment(.debugVideo)]
    )

    static let debugFile = MessagesMessage(
        rowID: -7,
        guid: "debug-file-message",
        sender: .debugContact,
        service: .iMessage,
        conversation: nil,
        receivedDate: Date(),
        parts: [.attachment(.debugFile)]
    )

    static let debugUnknownSender = MessagesMessage(
        rowID: -8,
        guid: "debug-unknown-sender-message",
        sender: .debugUnknown,
        service: .sms,
        conversation: nil,
        receivedDate: Date(),
        parts: [.text("This message was sent by an unknown contact.")]
    )
}
#endif
