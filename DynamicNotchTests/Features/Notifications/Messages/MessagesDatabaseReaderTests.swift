import Contacts
import Foundation
import XCTest
@testable import DynamicNotch

final class MessagesDatabaseReaderTests: XCTestCase {

    func testDatabaseURLReturnsExistingOverride() throws {
        let database = try MessagesTestDatabase()
        let reader = makeReader(databaseURL: database.url)

        XCTAssertEqual(reader.databaseURL(), database.url)
    }

    func testDatabaseURLReturnsNilForMissingOverride() {
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("chat.db")

        let reader = makeReader(databaseURL: missingURL)

        XCTAssertNil(reader.databaseURL())
    }

    func testLatestRowIDReturnsHighestIncomingRowID() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 10)
        try database.insertMessage(rowID: 42)
        try database.insertMessage(rowID: 100, isFromMe: true)

        let reader = makeReader(databaseURL: database.url)

        XCTAssertEqual(reader.latestRowID(), 42)
    }

    func testLatestRowIDReturnsZeroWhenMessageTableIsEmpty() throws {
        let database = try makeDatabase()
        let reader = makeReader(databaseURL: database.url)

        XCTAssertEqual(reader.latestRowID(), 0)
    }

    func testMessagesReturnsRowsAfterCheckpointInAscendingOrder() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 30, guid: "message-30")
        try database.insertMessage(rowID: 10, guid: "message-10")
        try database.insertMessage(rowID: 20, guid: "message-20")

        let reader = makeReader(databaseURL: database.url)
        let messages = try XCTUnwrap(reader.messages(after: 10))

        XCTAssertEqual(messages.map(\.rowID), [20, 30])
    }

    func testMessagesReturnsEmptyArrayWhenNoRowsMatch() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 10)

        let reader = makeReader(databaseURL: database.url)
        let messages = try XCTUnwrap(reader.messages(after: 10))

        XCTAssertTrue(messages.isEmpty)
    }

    func testMessagesExcludesOutgoingRows() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 1, guid: "incoming")
        try database.insertMessage(rowID: 2, guid: "outgoing", isFromMe: true)

        let reader = makeReader(databaseURL: database.url)
        let messages = try XCTUnwrap(reader.messages(after: 0))

        XCTAssertEqual(messages.map(\.rowID), [1])
    }

    func testMessagesExcludesAssociatedMessageRows() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 1, guid: "regular")
        try database.insertMessage(
            rowID: 2,
            guid: "reaction",
            associatedMessageGUID: "p:0/original-message"
        )

        let reader = makeReader(databaseURL: database.url)
        let messages = try XCTUnwrap(reader.messages(after: 0))

        XCTAssertEqual(messages.map(\.rowID), [1])
    }

    func testMessagesExcludesItemTypeRows() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 1, guid: "regular")
        try database.insertMessage(rowID: 2, guid: "item", itemType: 1)

        let reader = makeReader(databaseURL: database.url)
        let messages = try XCTUnwrap(reader.messages(after: 0))

        XCTAssertEqual(messages.map(\.rowID), [1])
    }

    func testMessagesExcludesGroupActionRows() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 1, guid: "regular")
        try database.insertMessage(rowID: 2, guid: "group-action", groupActionType: 1)

        let reader = makeReader(databaseURL: database.url)
        let messages = try XCTUnwrap(reader.messages(after: 0))

        XCTAssertEqual(messages.map(\.rowID), [1])
    }

    func testMessageWithRowIDReturnsMatchingMessage() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 10, guid: "message-10")
        try database.insertMessage(rowID: 20, guid: "message-20")

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 20))

        XCTAssertEqual(message.rowID, 20)
        XCTAssertEqual(message.guid, "message-20")
    }

    func testMessageWithRowIDReturnsNilForMissingRow() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 10)

        let reader = makeReader(databaseURL: database.url)

        XCTAssertNil(reader.message(withRowID: 999))
    }

    func testMessageWithRowIDReturnsNilForFilteredRow() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 10, isFromMe: true)

        let reader = makeReader(databaseURL: database.url)

        XCTAssertNil(reader.message(withRowID: 10))
    }

    func testMessageMapsCoreValues() throws {
        let database = try makeDatabase()
        let senderIdentifier = "reader-test@example.invalid"

        try database.insertHandle(rowID: 7, identifier: senderIdentifier)
        try database.insertMessage(
            rowID: 42,
            guid: "message-guid",
            text: "\n  Hello from Messages  \n",
            date: 1_234,
            service: "SMS",
            handleID: 7
        )

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 42))

        XCTAssertEqual(message.rowID, 42)
        XCTAssertEqual(message.guid, "message-guid")
        XCTAssertEqual(message.sender.identifier, senderIdentifier)
        XCTAssertEqual(message.sender.displayName, senderIdentifier)
        XCTAssertNil(message.sender.avatarData)
        XCTAssertFalse(message.sender.isKnownContact)
        XCTAssertEqual(message.service, .sms)
        XCTAssertEqual(message.receivedDate.timeIntervalSinceReferenceDate, 1_234, accuracy: 0.001)
        XCTAssertEqual(message.parts, [.text("Hello from Messages")])
    }

    func testMessageUsesFallbackGUIDWhenGUIDIsMissing() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 42, guid: nil)

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 42))

        XCTAssertEqual(message.guid, "message-42")
    }

    func testMessageMapsIMessageSMSAndUnknownServices() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 1, service: "iMessage")
        try database.insertMessage(rowID: 2, service: "SMS")
        try database.insertMessage(rowID: 3, service: "RCS")

        let reader = makeReader(databaseURL: database.url)
        let messages = try XCTUnwrap(reader.messages(after: 0))

        XCTAssertEqual(messages.map(\.service), [.iMessage, .sms, .unknown])
    }

    func testMessageMapsNanosecondDate() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 1, date: 1_234_000_000_000)

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 1))

        XCTAssertEqual(message.receivedDate.timeIntervalSinceReferenceDate, 1_234, accuracy: 0.001)
    }

    func testMessageUsesAttributedBodyWhenPlainTextIsUnavailable() throws {
        let database = try makeDatabase()
        let attributedBody = try keyedArchive("Archived Messages text")

        try database.insertMessage(
            rowID: 1,
            text: "\u{FFFC}",
            attributedBody: attributedBody
        )

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 1))

        XCTAssertEqual(message.parts, [.text("Archived Messages text")])
    }

    func testMessageMapsOneToOneConversation() throws {
        let database = try makeDatabase()

        try database.insertHandle(rowID: 1, identifier: "first@example.invalid")
        try database.insertChat(rowID: 10, identifier: "chat-10", displayName: nil)
        try database.linkHandle(1, toChat: 10)
        try database.insertMessage(rowID: 20, handleID: 1)
        try database.linkMessage(20, toChat: 10)

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 20))

        XCTAssertEqual(
            message.conversation,
            MessagesConversation(
                identifier: "chat-10",
                displayName: nil,
                isGroup: false
            )
        )
    }

    func testMessageMapsGroupConversation() throws {
        let database = try makeDatabase()

        try database.insertHandle(rowID: 1, identifier: "first@example.invalid")
        try database.insertHandle(rowID: 2, identifier: "second@example.invalid")
        try database.insertChat(rowID: 10, identifier: "group-10", displayName: "Design Team")
        try database.linkHandle(1, toChat: 10)
        try database.linkHandle(2, toChat: 10)
        try database.insertMessage(rowID: 20, handleID: 1)
        try database.linkMessage(20, toChat: 10)

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 20))

        XCTAssertEqual(
            message.conversation,
            MessagesConversation(
                identifier: "group-10",
                displayName: "Design Team",
                isGroup: true
            )
        )
    }

    func testMessageHasNoConversationWithoutChat() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 1)

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 1))

        XCTAssertNil(message.conversation)
    }

    func testMessageKeepsTextBeforeAttachmentsAndOrdersAttachmentsByJoinRowID() throws {
        let database = try makeDatabase()
        let imageURL = try database.createFile(named: "photo.jpg")
        let fileURL = try database.createFile(named: "document.pdf")

        try database.insertMessage(rowID: 1, text: "Look at this")

        try database.insertAttachment(
            rowID: 100,
            filename: imageURL.path,
            transferName: "Photo.jpg",
            mimeType: "image/jpeg",
            uti: "public.jpeg"
        )

        try database.insertAttachment(
            rowID: 200,
            filename: fileURL.path,
            transferName: "Document.pdf",
            mimeType: "application/pdf",
            uti: "com.adobe.pdf"
        )

        try database.linkAttachment(rowID: 20, messageID: 1, attachmentID: 100)
        try database.linkAttachment(rowID: 10, messageID: 1, attachmentID: 200)

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 1))

        XCTAssertEqual(
            message.parts,
            [
                .text("Look at this"),
                .attachment(
                    .file(
                        MessagesFileAttachment(
                            id: "200",
                            fileURL: fileURL.standardizedFileURL,
                            filename: "Document.pdf",
                            mimeType: "application/pdf",
                            uti: "com.adobe.pdf"
                        )
                    )
                ),
                .attachment(
                    .image(
                        MessagesImageAttachment(
                            id: "100",
                            fileURL: imageURL.standardizedFileURL,
                            width: nil,
                            height: nil
                        )
                    )
                )
            ]
        )
    }

    func testMessageExcludesHiddenAttachments() throws {
        let database = try makeDatabase()
        let visibleURL = try database.createFile(named: "visible.pdf")
        let hiddenURL = try database.createFile(named: "hidden.pdf")

        try database.insertMessage(rowID: 1, text: nil)

        try database.insertAttachment(
            rowID: 100,
            filename: visibleURL.path,
            transferName: "Visible.pdf",
            mimeType: "application/pdf",
            uti: "com.adobe.pdf"
        )

        try database.insertAttachment(
            rowID: 200,
            filename: hiddenURL.path,
            transferName: "Hidden.pdf",
            mimeType: "application/pdf",
            uti: "com.adobe.pdf",
            isHidden: true
        )

        try database.linkAttachment(rowID: 1, messageID: 1, attachmentID: 100)
        try database.linkAttachment(rowID: 2, messageID: 1, attachmentID: 200)

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 1))

        let attachmentIDs = message.parts.compactMap { part -> String? in
            guard case .attachment(let attachment) = part else { return nil }

            return attachment.id
        }

        XCTAssertEqual(attachmentIDs, ["100"])
    }

    func testMessageKeepsUnavailableAttachmentWithNilFileURL() throws {
        let database = try makeDatabase()
        let missingURL = database.url.deletingLastPathComponent().appendingPathComponent("missing.caf")

        try database.insertMessage(rowID: 1, text: nil)

        try database.insertAttachment(
            rowID: 100,
            filename: missingURL.path,
            transferName: "Voice Message.caf",
            mimeType: "audio/x-caf",
            uti: "public.audio"
        )

        try database.linkAttachment(rowID: 1, messageID: 1, attachmentID: 100)

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 1))

        XCTAssertEqual(
            message.parts,
            [
                .attachment(
                    .audio(
                        MessagesAudioAttachment(
                            id: "100",
                            fileURL: nil,
                            duration: nil
                        )
                    )
                )
            ]
        )
    }

    func testMessageCanContainNoParts() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 1, text: nil, attributedBody: nil)

        let reader = makeReader(databaseURL: database.url)
        let message = try XCTUnwrap(reader.message(withRowID: 1))

        XCTAssertTrue(message.parts.isEmpty)
    }

    func testMessagesReturnsNilWhenSchemaIsUnavailable() throws {
        let database = try MessagesTestDatabase()
        let reader = makeReader(databaseURL: database.url)

        XCTAssertNil(reader.messages(after: 0))
    }

    private func makeReader(databaseURL: URL) -> MessagesDatabaseReader {
        MessagesDatabaseReader(databaseURL: databaseURL, contactResolver: MessagesContactResolver(contactStore: DeniedMessagesContactStore()))
    }

    private func makeDatabase() throws -> MessagesTestDatabase {
        let database = try MessagesTestDatabase()

        try database.createSchema()

        return database
    }

    private func keyedArchive(_ text: String) throws -> Data {
        let attributedString = NSAttributedString(string: text)

        return try NSKeyedArchiver.archivedData(withRootObject: attributedString, requiringSecureCoding: true)
    }
}

private struct DeniedMessagesContactStore: MessagesContactStoring {
    let authorizationStatus: CNAuthorizationStatus = .denied

    func contact(matching identifier: String) throws -> CNContact? {
        XCTFail("MessagesDatabaseReaderTests must not access the system Contacts store")
        return nil
    }
}
