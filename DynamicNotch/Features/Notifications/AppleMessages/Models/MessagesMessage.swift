import Foundation

struct MessagesMessage: Equatable {
    let rowID: Int64
    let guid: String
    let sender: String
    let senderHandle: String
    let text: String
    let receivedDate: Date
    let isFromMe: Bool
}

#if DEBUG
extension MessagesMessage {
    static let debugPreview = debugPreviewStandard

    static let debugPreviewStandard = MessagesMessage(
        rowID: -1,
        guid: "debug-messages-standard",
        sender: "Jane Doe",
        senderHandle: "+1 (555) 019-2834",
        text: "Hey! Are you free for a quick sync this afternoon?",
        receivedDate: Date(),
        isFromMe: false
    )

    static let debugPreviewShort = MessagesMessage(
        rowID: -2,
        guid: "debug-messages-short",
        sender: "Alex Rivers",
        senderHandle: "alex.rivers@icloud.com",
        text: "See you there! 👍",
        receivedDate: Date(),
        isFromMe: false
    )

    static let debugPreviewLongContent = MessagesMessage(
        rowID: -3,
        guid: "debug-messages-long",
        sender: "Development Team Chat",
        senderHandle: "dev-team@internal",
        text: "The latest build is ready for testing. Please check the notifications integration and verify that multi-message updates smoothly transition without closing the notch.",
        receivedDate: Date(),
        isFromMe: false
    )

    static let debugPreviewNoText = MessagesMessage(
        rowID: -10,
        guid: "debug-messages-no-text",
        sender: "Jane Doe",
        senderHandle: "+1 (555) 019-2834",
        text: "",
        receivedDate: Date(),
        isFromMe: false
    )

    static let debugPreviewBatch: [MessagesMessage] = [
        debugPreviewStandard,
        debugPreviewShort,
        MessagesMessage(
            rowID: -4,
            guid: "debug-messages-batch-3",
            sender: "Michael Scott",
            senderHandle: "+1 (555) 329-8472",
            text: "Don't forget the all-hands meeting in conference room A!",
            receivedDate: Date(),
            isFromMe: false
        )
    ]
}
#endif
