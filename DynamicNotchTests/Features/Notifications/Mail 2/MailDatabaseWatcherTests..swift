import XCTest
@testable import DynamicNotch

final class MailDatabaseWatcherTests: XCTestCase {

    func testStartMonitoringPostsNotificationForNewMessage() throws {
        let database = try makeWatcherDatabase()
        let reader = MailDatabaseReader(databaseURL: database.url)
        let watcher = MailDatabaseWatcher(reader: reader)

        let notificationExpectation = expectation(forNotification: .mailDatabaseDidReceiveMessage, object: nil) { notification in
            guard let message = notification.object as? MailMessage else { return false }

            return message.rowID == 2
        }

        watcher.startMonitoring()

        Thread.sleep(forTimeInterval: 0.5)

        try database.insertMessage(rowID: 2, dataID: 2, receivedTimestamp: 2000)

        wait(
            for: [notificationExpectation],
            timeout: 3
        )

        watcher.stopMonitoring()
        Thread.sleep(forTimeInterval: 0.2)
    }

    func testStopMonitoringPreventsNotificationForNewMessage() throws {
        let database = try makeWatcherDatabase()
        let reader = MailDatabaseReader(databaseURL: database.url)
        let watcher = MailDatabaseWatcher(reader: reader)

        let notificationExpectation = expectation(forNotification: .mailDatabaseDidReceiveMessage, object: nil)

        notificationExpectation.isInverted = true

        watcher.startMonitoring()

        Thread.sleep(forTimeInterval: 0.5)

        watcher.stopMonitoring()

        Thread.sleep(forTimeInterval: 0.2)

        try database.insertMessage(rowID: 2, dataID: 2, receivedTimestamp: 2000)

        wait(
            for: [notificationExpectation],
            timeout: 1
        )
    }

    private func makeWatcherDatabase() throws -> MailTestDatabase {
        let database = try MailTestDatabase(usesWAL: true)

        try database.createMailSchema()
        try database.insertReferenceData()

        try database.insertMessage(rowID: 1, receivedTimestamp: 1000)

        return database
    }
}
