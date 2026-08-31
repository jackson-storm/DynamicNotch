import Foundation
import XCTest
@testable import DynamicNotch

final class MessagesDatabaseWatcherTests: XCTestCase {

    func testStartMonitoringPostsNotificationForNewMessage() throws {
        let database = try makeWatcherDatabase()
        let reader = MessagesDatabaseReader(databaseURL: database.url)
        let watcher = MessagesDatabaseWatcher(reader: reader)
        let messageExpectation = expectationForMessage(rowID: 2)

        startAndSettle(watcher)

        try insertCurrentMessage(rowID: 2, text: "New message", into: database)

        wait(for: [messageExpectation], timeout: 3)

        stopAndSettle(watcher)
    }

    func testStartMonitoringDoesNotReplayExistingMessage() throws {
        let database = try makeWatcherDatabase()
        let reader = MessagesDatabaseReader(databaseURL: database.url)
        let watcher = MessagesDatabaseWatcher(reader: reader)
        let messageExpectation = expectationForMessage(rowID: 1)

        messageExpectation.isInverted = true

        startAndSettle(watcher)

        wait(for: [messageExpectation], timeout: 1)

        stopAndSettle(watcher)
    }

    func testStopMonitoringPreventsNewMessageNotification() throws {
        let database = try makeWatcherDatabase()
        let reader = MessagesDatabaseReader(databaseURL: database.url)
        let watcher = MessagesDatabaseWatcher(reader: reader)
        let messageExpectation = expectationForMessage(rowID: 2)

        messageExpectation.isInverted = true

        startAndSettle(watcher)
        stopAndSettle(watcher)

        try insertCurrentMessage(rowID: 2, text: "Message after stop", into: database)

        wait(for: [messageExpectation], timeout: 1)
    }

    func testMonitoringPostsEveryMessageFromSingleDatabaseRead() throws {
        let database = try makeWatcherDatabase()
        let reader = MessagesDatabaseReader(databaseURL: database.url)
        let watcher = MessagesDatabaseWatcher(reader: reader)
        let firstMessageExpectation = expectationForMessage(rowID: 2)
        let secondMessageExpectation = expectationForMessage(rowID: 3)

        startAndSettle(watcher)

        try insertCurrentMessage(rowID: 2, text: "First message", into: database)
        try insertCurrentMessage(rowID: 3, text: "Second message", into: database)

        wait(for: [firstMessageExpectation, secondMessageExpectation], timeout: 3)

        stopAndSettle(watcher)
    }

    func testMonitoringIgnoresMessageReceivedBeforeMonitoringStarted() throws {
        let database = try makeWatcherDatabase()
        let reader = MessagesDatabaseReader(databaseURL: database.url)
        let watcher = MessagesDatabaseWatcher(reader: reader)
        let messageExpectation = expectationForMessage(rowID: 2)

        messageExpectation.isInverted = true

        startAndSettle(watcher)

        try database.insertMessage(
            rowID: 2,
            guid: "old-message",
            text: "Old message",
            date: Date().addingTimeInterval(-60).timeIntervalSinceReferenceDate
        )

        wait(for: [messageExpectation], timeout: 1)

        stopAndSettle(watcher)
    }

    func testMonitoringWaitsForAttachmentFileBeforePostingMessage() throws {
        let database = try makeWatcherDatabase()
        let reader = MessagesDatabaseReader(databaseURL: database.url)
        let watcher = MessagesDatabaseWatcher(reader: reader)
        let attachmentURL = database.url.deletingLastPathComponent().appendingPathComponent("attachment.bin")
        let prematureExpectation = expectationForMessage(rowID: 2)

        prematureExpectation.isInverted = true

        startAndSettle(watcher)

        try database.insertAttachment(
            rowID: 100,
            filename: attachmentURL.path,
            transferName: "Attachment.bin",
            mimeType: "application/octet-stream",
            uti: "public.data"
        )

        try database.linkAttachment(rowID: 1, messageID: 2, attachmentID: 100)

        try database.insertMessage(
            rowID: 2,
            guid: "file-message",
            text: nil,
            date: Date().timeIntervalSinceReferenceDate
        )

        wait(for: [prematureExpectation], timeout: 0.4)

        let readyExpectation = expectation(forNotification: .messagesDatabaseDidReceiveMessage, object: nil) { notification in
            guard let message = notification.object as? MessagesMessage else { return false }
            guard message.rowID == 2 else { return false }
            guard case .attachment(.file(let attachment)) = message.parts.first else { return false }

            return attachment.fileURL == attachmentURL.standardizedFileURL
        }

        _ = try database.createFile(named: "attachment.bin", data: Data([0]))

        wait(for: [readyExpectation], timeout: 3)

        stopAndSettle(watcher)
    }

    func testStopMonitoringCancelsPendingAttachmentRefresh() throws {
        let database = try makeWatcherDatabase()
        let reader = MessagesDatabaseReader(databaseURL: database.url)
        let watcher = MessagesDatabaseWatcher(reader: reader)
        let attachmentURL = database.url.deletingLastPathComponent().appendingPathComponent("attachment.bin")
        let prematureExpectation = expectationForMessage(rowID: 2)

        prematureExpectation.isInverted = true

        startAndSettle(watcher)

        try database.insertAttachment(
            rowID: 100,
            filename: attachmentURL.path,
            transferName: "Attachment.bin",
            mimeType: "application/octet-stream",
            uti: "public.data"
        )

        try database.linkAttachment(rowID: 1, messageID: 2, attachmentID: 100)

        try database.insertMessage(
            rowID: 2,
            guid: "file-message",
            text: nil,
            date: Date().timeIntervalSinceReferenceDate
        )

        wait(for: [prematureExpectation], timeout: 0.4)

        let notificationAfterStopExpectation = expectationForMessage(rowID: 2)

        notificationAfterStopExpectation.isInverted = true

        stopAndSettle(watcher)

        _ = try database.createFile(named: "attachment.bin", data: Data([0]))

        wait(for: [notificationAfterStopExpectation], timeout: 1)
    }

    func testMonitoringCanStartAgainAfterStopping() throws {
        let database = try makeWatcherDatabase()
        let reader = MessagesDatabaseReader(databaseURL: database.url)
        let watcher = MessagesDatabaseWatcher(reader: reader)

        startAndSettle(watcher)
        stopAndSettle(watcher)

        let messageExpectation = expectationForMessage(rowID: 2)

        startAndSettle(watcher)

        try insertCurrentMessage(rowID: 2, text: "Message after restart", into: database)

        wait(for: [messageExpectation], timeout: 3)

        stopAndSettle(watcher)
    }

    private func makeWatcherDatabase() throws -> MessagesTestDatabase {
        let database = try MessagesTestDatabase(usesWAL: true)

        try database.createSchema()

        try database.insertMessage(
            rowID: 1,
            guid: "existing-message",
            text: "Existing message",
            date: Date().addingTimeInterval(-60).timeIntervalSinceReferenceDate
        )

        return database
    }

    private func insertCurrentMessage(rowID: Int64, text: String, into database: MessagesTestDatabase) throws {
        try database.insertMessage(
            rowID: rowID,
            guid: "message-\(rowID)",
            text: text,
            date: Date().timeIntervalSinceReferenceDate
        )
    }

    private func expectationForMessage(rowID: Int64) -> XCTestExpectation {
        expectation(forNotification: .messagesDatabaseDidReceiveMessage, object: nil) { notification in
            guard let message = notification.object as? MessagesMessage else { return false }

            return message.rowID == rowID
        }
    }

    private func startAndSettle(_ watcher: MessagesDatabaseWatcher) {
        watcher.startMonitoring()
        Thread.sleep(forTimeInterval: 0.5)
    }

    private func stopAndSettle(_ watcher: MessagesDatabaseWatcher) {
        watcher.stopMonitoring()
        Thread.sleep(forTimeInterval: 0.3)
    }
}
