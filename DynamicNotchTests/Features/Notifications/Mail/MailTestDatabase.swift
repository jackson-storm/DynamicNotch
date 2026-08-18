import Foundation
import SQLite3

final class MailTestDatabase {

    let url: URL

    private let directoryURL: URL
    private var connection: OpaquePointer?

    init(usesWAL: Bool = false) throws {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

        self.directoryURL = directoryURL
        self.url = directoryURL.appendingPathComponent("Envelope Index")

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        var database: OpaquePointer?

        guard sqlite3_open(url.path, &database) == SQLITE_OK, let database else {
            sqlite3_close(database)
            throw MailTestDatabaseError.databaseOpenFailed
        }

        connection = database

        do {
            if usesWAL {
                try execute(
                    """
                    PRAGMA journal_mode=WAL;
                    PRAGMA wal_autocheckpoint=0;
                    """
                )
            }
        } catch {
            sqlite3_close(database)
            connection = nil
            try? FileManager.default.removeItem(at: directoryURL)
            throw error
        }
    }

    deinit {
        if let connection {
            sqlite3_close(connection)
        }

        try? FileManager.default.removeItem(at: directoryURL)
    }

    //Create the minimal messages table used by latestRowID tests
    func createMessagesOnlySchema() throws {
        try execute(
            """
            CREATE TABLE messages (
                ROWID INTEGER PRIMARY KEY,
                deleted INTEGER NOT NULL
            );
            """
        )
    }

    //Insert a message into the minimal messages table
    func insertSimpleMessage(rowID: Int64, deleted: Bool) throws {
        try execute(
            """
            INSERT INTO messages (ROWID, deleted)
            VALUES (\(rowID), \(deleted ? 1 : 0));
            """
        )
    }

    //Create the Mail tables required by MailDatabaseReader queries
    func createMailSchema() throws {
        try execute(
            """
            CREATE TABLE messages (
                ROWID INTEGER PRIMARY KEY,
                mailbox INTEGER,
                global_message_id INTEGER,
                sender INTEGER,
                subject INTEGER,
                summary INTEGER,
                date_received INTEGER,
                deleted INTEGER NOT NULL
            );

            CREATE TABLE mailboxes (
                ROWID INTEGER PRIMARY KEY,
                url TEXT
            );

            CREATE TABLE message_global_data (
                ROWID INTEGER PRIMARY KEY,
                message_id_header TEXT
            );

            CREATE TABLE addresses (
                ROWID INTEGER PRIMARY KEY,
                address TEXT
            );

            CREATE TABLE subjects (
                ROWID INTEGER PRIMARY KEY,
                subject TEXT
            );

            CREATE TABLE summaries (
                ROWID INTEGER PRIMARY KEY,
                summary TEXT
            );
            """
        )
    }

    //Insert shared lookup values used by Mail reader and watcher tests
    func insertReferenceData() throws {
        try execute(
            """
            INSERT INTO mailboxes VALUES
                (1, '/Inbox'),
                (2, '/Trash');

            INSERT INTO addresses VALUES
                (1, 'sender@example.com'),
                (2, 'second@example.com');

            INSERT INTO subjects VALUES
                (1, 'Test subject'),
                (2, 'Second subject');

            INSERT INTO summaries VALUES
                (1, 'Preview text'),
                (2, 'Second preview');

            INSERT INTO message_global_data VALUES
                (1, '<message@example.com>'),
                (2, '<second@example.com>');
            """
        )
    }

    //Insert a message using one of the shared reference data rows
    func insertMessage(rowID: Int64, mailboxID: Int64 = 1, dataID: Int64 = 1, receivedTimestamp: Int64, deleted: Bool = false) throws {
        try execute(
            """
            INSERT INTO messages (
                ROWID,
                mailbox,
                global_message_id,
                sender,
                subject,
                summary,
                date_received,
                deleted
            )
            VALUES (
                \(rowID),
                \(mailboxID),
                \(dataID),
                \(dataID),
                \(dataID),
                \(dataID),
                \(receivedTimestamp),
                \(deleted ? 1 : 0)
            );
            """
        )
    }

    //Execute SQL against the temporary test database
    private func execute(_ sql: String) throws {
        
        guard let connection else {
            throw MailTestDatabaseError.databaseClosed
        }

        var errorMessage: UnsafeMutablePointer<CChar>?

        guard sqlite3_exec(connection, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown SQLite error"

            sqlite3_free(errorMessage)

            throw MailTestDatabaseError.sqlFailed(message)
        }
    }
}

enum MailTestDatabaseError: Error {
    case databaseOpenFailed
    case databaseClosed
    case sqlFailed(String)
}
