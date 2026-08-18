import XCTest
@testable import DynamicNotch

final class MailManagerTests: XCTestCase {

    func testStartMonitoringForwardsReceivedMessage() throws {
        let database = try makeTestDatabase()
        let reader = MailDatabaseReader(databaseURL: database.url)
        let manager = MailManager(reader: reader)

        let expectedMessage = makeMessage(rowID: 2)
        let messageExpectation = expectation(description: "Mail message received")

        var receivedMessage: MailMessage?

        manager.onMessageReceived = { message in
            receivedMessage = message
            messageExpectation.fulfill()
        }

        manager.startMonitoring()

        NotificationCenter.default.post(name: .mailDatabaseDidReceiveMessage, object: expectedMessage)

        wait(
            for: [messageExpectation],
            timeout: 1
        )

        XCTAssertEqual(receivedMessage, expectedMessage)

        manager.stopMonitoring()
    }

    func testStopMonitoringStopsForwardingReceivedMessages() throws {
        let database = try makeTestDatabase()
        let reader = MailDatabaseReader(databaseURL: database.url)
        let manager = MailManager(reader: reader)

        let messageExpectation = expectation(description: "Mail message should not be received")
        messageExpectation.isInverted = true

        manager.onMessageReceived = { _ in
            messageExpectation.fulfill()
        }

        manager.startMonitoring()
        manager.stopMonitoring()

        NotificationCenter.default.post(name: .mailDatabaseDidReceiveMessage, object: makeMessage(rowID: 2))

        wait(
            for: [messageExpectation],
            timeout: 0.5
        )
    }

    private func makeTestDatabase() throws -> MailTestDatabase {
        let database = try MailTestDatabase()

        try database.createMessagesOnlySchema()
        try database.insertSimpleMessage(rowID: 1, deleted: false)

        return database
    }

    private func makeMessage(rowID: Int64) -> MailMessage {
        MailMessage(
            rowID: rowID,
            messageIDHeader: "<test@example.com>",
            sender: "sender@example.com",
            subject: "Test subject",
            summary: "Test preview",
            receivedDate: Date(timeIntervalSince1970: 1_000)
        )
    }
}
