import XCTest
@testable import DynamicNotch

@MainActor
final class MessagesNotchContentTests: XCTestCase {

    func testPresentationConfigurationUsesMessagesRegistryAndKeepsContainerTapDisabled() {
        let content = makeContent(messages: [makeTextMessage(rowID: 1)])

        XCTAssertEqual(content.id, NotchContentRegistry.Notifications.messages.id)
        XCTAssertEqual(content.stackID, NotchContentRegistry.Notifications.messages.id)
        XCTAssertEqual(content.priority, NotchContentRegistry.Notifications.messages.priority)
        XCTAssertFalse(content.isExpandable)
        XCTAssertFalse(content.usesContentResizeEffect)
        XCTAssertNil(content.windowLink)
    }

    func testCornerRadiiMatchMessagesDesign() {
        let singleContent = makeContent(messages: [makeTextMessage(rowID: 1)])
        let cornerRadius = singleContent.cornerRadius(baseRadius: 15)

        XCTAssertEqual(cornerRadius.top, 28)
        XCTAssertEqual(cornerRadius.bottom, 38)
        XCTAssertEqual(singleContent.dynamicIslandCornerRadius(baseHeight: 40), 16)

        let multipleContent = makeContent(messages: [
            makeTextMessage(rowID: 1),
            makeTextMessage(rowID: 2)
        ])
        XCTAssertEqual(multipleContent.dynamicIslandCornerRadius(baseHeight: 40), 8)
    }

    func testDynamicIslandBottomPaddingMatchesDesign() {
        XCTAssertEqual(MessagesNotchContent.dynamicIslandBottomPadding, 12)
    }

    func testRowHeightClassifiesTextPreviewsAndPlayableAudio() {
        let textMessage = makeTextMessage(rowID: 1)
        let imageMessage = makeImageMessage(rowID: 2)
        let videoMessage = makeVideoMessage(rowID: 3)
        let fileMessage = makeFileMessage(rowID: 4)
        let audioMessage = makeAudioMessage(rowID: 5)

        XCTAssertEqual(MessagesNotchContent.rowHeight(for: textMessage), MessagesNotchContent.regularRowHeight)
        XCTAssertEqual(MessagesNotchContent.rowHeight(for: imageMessage), MessagesNotchContent.attachmentRowHeight)
        XCTAssertEqual(MessagesNotchContent.rowHeight(for: videoMessage), MessagesNotchContent.attachmentRowHeight)
        XCTAssertEqual(MessagesNotchContent.rowHeight(for: fileMessage), MessagesNotchContent.attachmentRowHeight)
        XCTAssertEqual(MessagesNotchContent.rowHeight(for: audioMessage), MessagesNotchContent.audioRowHeight)
    }

    func testAudioWithoutFileIsNotTreatedAsPlayable() {
        let message = makeAudioMessage(rowID: 1, fileURL: nil)

        XCTAssertFalse(MessagesNotchContent.hasPlayableAudio(in: message))
        XCTAssertEqual(MessagesNotchContent.rowHeight(for: message), MessagesNotchContent.regularRowHeight)
    }

    func testAttachmentPreviewClassificationExcludesAudio() {
        XCTAssertTrue(MessagesNotchContent.hasAttachmentPreview(in: makeImageMessage(rowID: 1)))
        XCTAssertTrue(MessagesNotchContent.hasAttachmentPreview(in: makeVideoMessage(rowID: 2)))
        XCTAssertTrue(MessagesNotchContent.hasAttachmentPreview(in: makeFileMessage(rowID: 3)))
        XCTAssertFalse(MessagesNotchContent.hasAttachmentPreview(in: makeAudioMessage(rowID: 4)))
    }

    func testStandardSizeUsesCompactHeightForShortText() {
        let content = makeContent(messages: [makeTextMessage(rowID: 1)])

        let size = content.size(baseWidth: 200, baseHeight: 40)

        XCTAssertEqual(size, CGSize(width: 360, height: 100))
    }

    func testStandardSizeAddsHeightForMultilineText() {
        let message = makeTextMessage(rowID: 1, text: "First line\nSecond line")
        let content = makeContent(messages: [message])

        let size = content.size(baseWidth: 200, baseHeight: 40)

        XCTAssertEqual(size, CGSize(width: 360, height: 115))
    }

    func testStandardSizeAddsHeightForAttachmentPreview() {
        let content = makeContent(messages: [makeImageMessage(rowID: 1)])

        let size = content.size(baseWidth: 200, baseHeight: 40)

        XCTAssertEqual(size, CGSize(width: 360, height: 110))
    }

    func testStandardSizeAddsHeightForPlayableAudio() {
        let content = makeContent(messages: [makeAudioMessage(rowID: 1)])

        let size = content.size(baseWidth: 200, baseHeight: 40)

        XCTAssertEqual(size, CGSize(width: 360, height: 120))
    }

    func testDynamicIslandSizesUseContentSpecificWidthsAndHeights() {
        let textContent = makeContent(messages: [makeTextMessage(rowID: 1)])
        let imageContent = makeContent(messages: [makeImageMessage(rowID: 2)])
        let audioContent = makeContent(messages: [makeAudioMessage(rowID: 3)])

        XCTAssertEqual(
            textContent.dynamicIslandSize(baseWidth: 200, baseHeight: 40),
            CGSize(width: 380, height: 100)
        )

        XCTAssertEqual(
            imageContent.dynamicIslandSize(baseWidth: 200, baseHeight: 40),
            CGSize(width: 410, height: 107)
        )

        XCTAssertEqual(
            audioContent.dynamicIslandSize(baseWidth: 200, baseHeight: 40),
            CGSize(width: 410, height: 117)
        )
    }

    func testQueueAddsBothRowsSpacingAndBottomPadding() {
        let content = makeContent(
            messages: [
                makeTextMessage(rowID: 1),
                makeTextMessage(rowID: 2)
            ]
        )

        let size = content.size(baseWidth: 200, baseHeight: 40)

        XCTAssertEqual(size, CGSize(width: 360, height: 165))
    }

    func testQueuePreservesTopClearanceForMultilineFirstMessage() {
        let content = makeContent(
            messages: [
                makeTextMessage(rowID: 1, text: "First line\nSecond line"),
                makeTextMessage(rowID: 2)
            ]
        )

        let size = content.size(baseWidth: 200, baseHeight: 40)

        XCTAssertEqual(size, CGSize(width: 360, height: 175))
    }

    func testOnlyLastTwoMessagesAffectQueueSize() {
        let content = makeContent(
            messages: [
                makeAudioMessage(rowID: 1),
                makeTextMessage(rowID: 2),
                makeImageMessage(rowID: 3)
            ]
        )

        let standardSize = content.size(baseWidth: 200, baseHeight: 40)
        let dynamicIslandSize = content.dynamicIslandSize(baseWidth: 200, baseHeight: 40)

        XCTAssertEqual(standardSize, CGSize(width: 360, height: 179))
        XCTAssertEqual(dynamicIslandSize, CGSize(width: 410, height: 176))
    }

    func testEmptyContentUsesSafeFallbackSize() {
        let content = makeContent(messages: [])

        let standardSize = content.size(baseWidth: 200, baseHeight: 40)
        let dynamicIslandSize = content.dynamicIslandSize(baseWidth: 200, baseHeight: 40)

        XCTAssertEqual(standardSize, CGSize(width: 360, height: 100))
        XCTAssertEqual(dynamicIslandSize, CGSize(width: 380, height: 100))
    }

    private func makeContent(messages: [MessagesMessage]) -> MessagesNotchContent {
        MessagesNotchContent(messages: messages, onOpen: { _ in })
    }

    private func makeTextMessage(rowID: Int64, text: String = "Hello") -> MessagesMessage {
        makeMessage(rowID: rowID, parts: [.text(text)])
    }

    private func makeImageMessage(rowID: Int64) -> MessagesMessage {
        makeMessage(
            rowID: rowID,
            parts: [
                .attachment(
                    .image(
                        MessagesImageAttachment(
                            id: "image-\(rowID)",
                            fileURL: URL(fileURLWithPath: "/tmp/photo.jpg"),
                            width: 100,
                            height: 80
                        )
                    )
                )
            ]
        )
    }

    private func makeVideoMessage(rowID: Int64) -> MessagesMessage {
        makeMessage(
            rowID: rowID,
            parts: [
                .attachment(
                    .video(
                        MessagesVideoAttachment(
                            id: "video-\(rowID)",
                            fileURL: URL(fileURLWithPath: "/tmp/video.mov"),
                            duration: 12
                        )
                    )
                )
            ]
        )
    }

    private func makeFileMessage(rowID: Int64) -> MessagesMessage {
        makeMessage(
            rowID: rowID,
            parts: [
                .attachment(
                    .file(
                        MessagesFileAttachment(
                            id: "file-\(rowID)",
                            fileURL: URL(fileURLWithPath: "/tmp/document.pdf"),
                            filename: "Document.pdf",
                            mimeType: "application/pdf",
                            uti: "com.adobe.pdf"
                        )
                    )
                )
            ]
        )
    }

    private func makeAudioMessage(
        rowID: Int64,
        fileURL: URL? = URL(fileURLWithPath: "/tmp/voice.caf")
    ) -> MessagesMessage {
        makeMessage(
            rowID: rowID,
            parts: [
                .attachment(
                    .audio(
                        MessagesAudioAttachment(
                            id: "audio-\(rowID)",
                            fileURL: fileURL,
                            duration: 30
                        )
                    )
                )
            ]
        )
    }

    private func makeMessage(rowID: Int64, parts: [MessagesMessagePart]) -> MessagesMessage {
        MessagesMessage(
            rowID: rowID,
            guid: "message-\(rowID)",
            sender: MessagesSender(identifier: "+123456789", displayName: "Tim Cook", avatarData: nil),
            service: .iMessage,
            conversation: nil,
            receivedDate: Date(timeIntervalSinceReferenceDate: Double(rowID)),
            parts: parts
        )
    }
}
