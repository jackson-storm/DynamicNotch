import XCTest
@testable import DynamicNotch

@MainActor
final class MessagesManagerTests: XCTestCase {

    func testManagerDoesNotForwardMessageBeforeMonitoringStarts() throws {
        let context = try makeContext()
        let expectedMessage = makeMessage()
        var receivedMessage: MessagesMessage?

        context.manager.onMessageReceived = { message in
            receivedMessage = message
        }

        post(expectedMessage)

        XCTAssertNil(receivedMessage)
    }

    func testStartMonitoringForwardsReceivedMessage() throws {
        let context = try makeContext()
        let expectedMessage = makeMessage()
        var receivedMessage: MessagesMessage?

        defer {
            context.manager.stopMonitoring()
        }

        context.manager.onMessageReceived = { message in
            receivedMessage = message
        }

        context.manager.startMonitoring()
        post(expectedMessage)

        XCTAssertEqual(receivedMessage, expectedMessage)
    }

    func testStartMonitoringDoesNotCreateDuplicateObservers() throws {
        let context = try makeContext()
        var receivedMessageCount = 0

        defer {
            context.manager.stopMonitoring()
        }

        context.manager.onMessageReceived = { _ in
            receivedMessageCount += 1
        }

        context.manager.startMonitoring()
        context.manager.startMonitoring()
        post(makeMessage())

        XCTAssertEqual(receivedMessageCount, 1)
    }

    func testStopMonitoringStopsForwardingMessages() throws {
        let context = try makeContext()
        var receivedMessage: MessagesMessage?

        context.manager.onMessageReceived = { message in
            receivedMessage = message
        }

        context.manager.startMonitoring()
        context.manager.stopMonitoring()
        post(makeMessage())

        XCTAssertNil(receivedMessage)
    }

    func testMonitoringCanStartAgainAfterStopping() throws {
        let context = try makeContext()
        let expectedMessage = makeMessage(rowID: 2)
        var receivedMessage: MessagesMessage?

        defer {
            context.manager.stopMonitoring()
        }

        context.manager.onMessageReceived = { message in
            receivedMessage = message
        }

        context.manager.startMonitoring()
        context.manager.stopMonitoring()
        context.manager.startMonitoring()
        post(expectedMessage)

        XCTAssertEqual(receivedMessage, expectedMessage)
    }

    func testInvalidNotificationObjectIsIgnored() throws {
        let context = try makeContext()
        var receivedMessageCount = 0

        defer {
            context.manager.stopMonitoring()
        }

        context.manager.onMessageReceived = { _ in
            receivedMessageCount += 1
        }

        context.manager.startMonitoring()
        post("Invalid message")

        XCTAssertEqual(receivedMessageCount, 0)
    }

    private func makeContext() throws -> TestContext {
        let database = try MessagesTestDatabase(usesWAL: true)

        try database.createSchema()

        let reader = MessagesDatabaseReader(databaseURL: database.url)
        let manager = MessagesManager(reader: reader)

        return TestContext(database: database, manager: manager)
    }

    private func makeMessage(rowID: Int64 = 1) -> MessagesMessage {
        MessagesMessage(
            rowID: rowID,
            guid: "message-\(rowID)",
            sender: MessagesSender(identifier: "+123456789", displayName: "Tim Cook", avatarData: nil),
            service: .iMessage,
            conversation: nil,
            receivedDate: Date(timeIntervalSinceReferenceDate: 1_000),
            parts: [.text("Test message")]
        )
    }

    private func post(_ object: Any?) {
        NotificationCenter.default.post(name: .messagesDatabaseDidReceiveMessage, object: object)
    }

    private struct TestContext {
        let database: MessagesTestDatabase
        let manager: MessagesManager
    }
}
