import Foundation
import SQLite3

final class MessagesTestDatabase {

    let url: URL

    private let directoryURL: URL
    private var connection: OpaquePointer?

    init(usesWAL: Bool = false) throws {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

        self.directoryURL = directoryURL
        self.url = directoryURL.appendingPathComponent("chat.db")

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        var database: OpaquePointer?

        guard sqlite3_open(url.path, &database) == SQLITE_OK, let database else {
            sqlite3_close(database)
            try? FileManager.default.removeItem(at: directoryURL)
            throw MessagesTestDatabaseError.databaseOpenFailed
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

    func createSchema() throws {
        try execute(
            """
            CREATE TABLE message (
                ROWID INTEGER PRIMARY KEY,
                guid TEXT,
                text TEXT,
                attributedBody BLOB,
                date REAL,
                service TEXT,
                handle_id INTEGER,
                is_from_me INTEGER NOT NULL DEFAULT 0,
                associated_message_guid TEXT,
                item_type INTEGER NOT NULL DEFAULT 0,
                group_action_type INTEGER NOT NULL DEFAULT 0
            );

            CREATE TABLE handle (
                ROWID INTEGER PRIMARY KEY,
                id TEXT
            );

            CREATE TABLE chat (
                ROWID INTEGER PRIMARY KEY,
                chat_identifier TEXT,
                display_name TEXT
            );

            CREATE TABLE chat_message_join (
                chat_id INTEGER NOT NULL,
                message_id INTEGER NOT NULL
            );

            CREATE TABLE chat_handle_join (
                chat_id INTEGER NOT NULL,
                handle_id INTEGER NOT NULL
            );

            CREATE TABLE attachment (
                ROWID INTEGER PRIMARY KEY,
                filename TEXT,
                transfer_name TEXT,
                mime_type TEXT,
                uti TEXT,
                hide_attachment INTEGER NOT NULL DEFAULT 0
            );

            CREATE TABLE message_attachment_join (
                ROWID INTEGER PRIMARY KEY,
                message_id INTEGER NOT NULL,
                attachment_id INTEGER NOT NULL
            );
            """
        )
    }

    func insertHandle(rowID: Int64, identifier: String) throws {
        try execute(
            """
            INSERT INTO handle (
                ROWID,
                id
            )
            VALUES (
                \(rowID),
                \(sqlValue(identifier))
            );
            """
        )
    }

    func insertChat(rowID: Int64, identifier: String?, displayName: String?) throws {
        try execute(
            """
            INSERT INTO chat (
                ROWID,
                chat_identifier,
                display_name
            )
            VALUES (
                \(rowID),
                \(sqlValue(identifier)),
                \(sqlValue(displayName))
            );
            """
        )
    }

    func linkHandle(_ handleID: Int64, toChat chatID: Int64) throws {
        try execute(
            """
            INSERT INTO chat_handle_join (
                chat_id,
                handle_id
            )
            VALUES (
                \(chatID),
                \(handleID)
            );
            """
        )
    }

    func linkMessage(_ messageID: Int64, toChat chatID: Int64) throws {
        try execute(
            """
            INSERT INTO chat_message_join (
                chat_id,
                message_id
            )
            VALUES (
                \(chatID),
                \(messageID)
            );
            """
        )
    }

    func insertMessage(
        rowID: Int64,
        guid: String? = nil,
        text: String? = "Test message",
        attributedBody: Data? = nil,
        date: Double = 1_000,
        service: String? = "iMessage",
        handleID: Int64? = nil,
        isFromMe: Bool = false,
        associatedMessageGUID: String? = nil,
        itemType: Int = 0,
        groupActionType: Int = 0
    ) throws {
        try execute(
            """
            INSERT INTO message (
                ROWID,
                guid,
                text,
                attributedBody,
                date,
                service,
                handle_id,
                is_from_me,
                associated_message_guid,
                item_type,
                group_action_type
            )
            VALUES (
                \(rowID),
                \(sqlValue(guid)),
                \(sqlValue(text)),
                \(sqlValue(attributedBody)),
                \(date),
                \(sqlValue(service)),
                \(sqlValue(handleID)),
                \(isFromMe ? 1 : 0),
                \(sqlValue(associatedMessageGUID)),
                \(itemType),
                \(groupActionType)
            );
            """
        )
    }

    func insertAttachment(
        rowID: Int64,
        filename: String? = nil,
        transferName: String? = nil,
        mimeType: String? = nil,
        uti: String? = nil,
        isHidden: Bool = false
    ) throws {
        try execute(
            """
            INSERT INTO attachment (
                ROWID,
                filename,
                transfer_name,
                mime_type,
                uti,
                hide_attachment
            )
            VALUES (
                \(rowID),
                \(sqlValue(filename)),
                \(sqlValue(transferName)),
                \(sqlValue(mimeType)),
                \(sqlValue(uti)),
                \(isHidden ? 1 : 0)
            );
            """
        )
    }

    func linkAttachment(rowID: Int64, messageID: Int64, attachmentID: Int64) throws {
        try execute(
            """
            INSERT INTO message_attachment_join (
                ROWID,
                message_id,
                attachment_id
            )
            VALUES (
                \(rowID),
                \(messageID),
                \(attachmentID)
            );
            """
        )
    }

    func createFile(named filename: String, data: Data = Data()) throws -> URL {
        let fileURL = directoryURL.appendingPathComponent(filename)

        try data.write(to: fileURL, options: .atomic)

        return fileURL
    }

    private func execute(_ sql: String) throws {
        guard let connection else {
            throw MessagesTestDatabaseError.databaseClosed
        }

        var errorMessage: UnsafeMutablePointer<CChar>?

        guard sqlite3_exec(connection, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown SQLite error"

            sqlite3_free(errorMessage)

            throw MessagesTestDatabaseError.sqlFailed(message)
        }
    }

    private func sqlValue(_ value: String?) -> String {
        guard let value else { return "NULL" }

        let escapedValue = value.replacingOccurrences(of: "'", with: "''")

        return "'\(escapedValue)'"
    }

    private func sqlValue(_ value: Int64?) -> String {
        guard let value else { return "NULL" }

        return String(value)
    }

    private func sqlValue(_ value: Data?) -> String {
        guard let value else { return "NULL" }

        let hexadecimalValue = value.map { String(format: "%02X", $0) }.joined()

        return "X'\(hexadecimalValue)'"
    }
}

enum MessagesTestDatabaseError: Error {
    case databaseOpenFailed
    case databaseClosed
    case sqlFailed(String)
}
