import Foundation
import OSLog
import SQLite3

final class MessagesDatabaseReader {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MessagesDatabaseReader")

    private let databaseURLOverride: URL?
    private let attachmentReader: MessagesAttachmentReader
    private let contactResolver: MessagesContactResolver
    private let attributedBodyDecoder: MessagesAttributedBodyDecoder

    init(
        databaseURL: URL? = nil,
        attachmentReader: MessagesAttachmentReader = MessagesAttachmentReader(),
        contactResolver: MessagesContactResolver = MessagesContactResolver(),
        attributedBodyDecoder: MessagesAttributedBodyDecoder = MessagesAttributedBodyDecoder()
    ) {
        self.databaseURLOverride = databaseURL
        self.attachmentReader = attachmentReader
        self.contactResolver = contactResolver
        self.attributedBodyDecoder = attributedBodyDecoder
    }

    func databaseURL() -> URL? {
        if let databaseURLOverride {
            return FileManager.default.fileExists(atPath: databaseURLOverride.path) ? databaseURLOverride : nil
        }

        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Messages/chat.db")

        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func latestRowID() -> Int64? {
        inDatabase { database in
            let query = """
            SELECT COALESCE(MAX(ROWID), 0)
            FROM message
            WHERE is_from_me = 0;
            """

            return self.inStatement(
                database: database,
                query: query,
                errorMessage: "Could not read latest Messages RowID"
            ) { statement in
                guard sqlite3_step(statement) == SQLITE_ROW else {
                    self.logDatabaseError("Could not read latest Messages RowID", database: database)
                    return nil
                }

                return sqlite3_column_int64(statement, 0)
            }
        }
    }

    func messages(after rowID: Int64) -> [MessagesMessage]? {
        inDatabase { database in
            self.readMessages(database: database, condition: "m.ROWID > ?", rowID: rowID)
        }
    }

    func message(withRowID rowID: Int64) -> MessagesMessage? {
        inDatabase { database in
            self.readMessages(database: database, condition: "m.ROWID = ?", rowID: rowID)?.first
        }
    }

    private func readMessages(database: OpaquePointer, condition: String, rowID: Int64) -> [MessagesMessage]? {
        let query = """
        SELECT
            m.ROWID,
            m.guid,
            m.text,
            m.attributedBody,
            m.date,
            m.service,
            h.id,
            c.chat_identifier,
            c.display_name,
            CASE
                WHEN (
                    SELECT COUNT(*)
                    FROM chat_handle_join AS chj
                    WHERE chj.chat_id = c.ROWID
                ) > 1
                THEN 1
                ELSE 0
            END
        FROM message AS m
        LEFT JOIN handle AS h
            ON h.ROWID = m.handle_id
        LEFT JOIN chat_message_join AS cmj
            ON cmj.message_id = m.ROWID
        LEFT JOIN chat AS c
            ON c.ROWID = cmj.chat_id
        WHERE
            \(condition)
            AND m.is_from_me = 0
            AND NULLIF(m.associated_message_guid, '') IS NULL
            AND COALESCE(m.item_type, 0) = 0
            AND COALESCE(m.group_action_type, 0) = 0
        GROUP BY m.ROWID
        ORDER BY m.ROWID ASC;
        """

        return inStatement(
            database: database,
            query: query,
            errorMessage: "Could not prepare Messages query"
        ) { statement in
            guard sqlite3_bind_int64(statement, 1, rowID) == SQLITE_OK else {
                self.logDatabaseError("Could not bind Messages RowID", database: database)
                return nil
            }

            var messages: [MessagesMessage] = []
            var result = sqlite3_step(statement)

            while result == SQLITE_ROW {
                messages.append(self.makeMessage(from: statement, database: database))
                result = sqlite3_step(statement)
            }

            guard result == SQLITE_DONE else {
                self.logDatabaseError("Could not read Messages rows", database: database)
                return nil
            }

            return messages
        }
    }

    private func makeMessage(from statement: OpaquePointer, database: OpaquePointer) -> MessagesMessage {
        let rowID = sqlite3_column_int64(statement, 0)
        let guid = stringValue(from: statement, column: 1) ?? "message-\(rowID)"
        let text = attributedBodyDecoder.decode(text: stringValue(from: statement, column: 2), attributedBody: dataValue(from: statement, column: 3))
        let senderIdentifier = stringValue(from: statement, column: 6) ?? ""
        let sender = senderIdentifier.isEmpty ? MessagesSender(identifier: "", displayName: "", avatarData: nil) : contactResolver.sender(for: senderIdentifier)
        let attachments = attachmentReader.attachments(for: rowID, database: database)

        var parts: [MessagesMessagePart] = []

        if let text {
            parts.append(.text(text))
        }

        parts.append(contentsOf: attachments.map { .attachment($0) })

        return MessagesMessage(
            rowID: rowID,
            guid: guid,
            sender: sender,
            service: MessagesService(databaseValue: stringValue(from: statement, column: 5)),
            conversation: conversation(from: statement),
            receivedDate: messageDate(from: statement, column: 4),
            parts: parts
        )
    }

    private func conversation(from statement: OpaquePointer) -> MessagesConversation? {
        let identifier = stringValue(from: statement, column: 7)
        let displayName = stringValue(from: statement, column: 8)

        guard identifier != nil || displayName != nil else { return nil }

        return MessagesConversation(identifier: identifier, displayName: displayName, isGroup: sqlite3_column_int(statement, 9) != 0)
    }

    private func inDatabase<T>(_ operation: (OpaquePointer) -> T?) -> T? {
        guard let databaseURL = databaseURL() else {
            logger.error("Messages database was not found")
            return nil
        }

        var database: OpaquePointer?

        let result = sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READONLY,
            nil
        )

        guard result == SQLITE_OK, let database else {
            logger.error("Could not open Messages database: \(self.errorMessage(database), privacy: .public)")
            sqlite3_close(database)
            return nil
        }

        defer {
            sqlite3_close(database)
        }

        sqlite3_busy_timeout(database, 1_000)

        return operation(database)
    }

    private func inStatement<T>(
        database: OpaquePointer,
        query: String,
        errorMessage: String,
        operation: (OpaquePointer) -> T?
    ) -> T? {
        var statement: OpaquePointer?

        let result = sqlite3_prepare_v2(
            database,
            query,
            -1,
            &statement,
            nil
        )

        guard result == SQLITE_OK, let statement else {
            logger.error("\(errorMessage, privacy: .public): \(self.errorMessage(database), privacy: .public)")
            sqlite3_finalize(statement)
            return nil
        }

        defer {
            sqlite3_finalize(statement)
        }

        return operation(statement)
    }

    private func stringValue(from statement: OpaquePointer, column: Int32) -> String? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL else { return nil }
        guard let value = sqlite3_column_text(statement, column) else { return nil }

        return String(cString: value)
    }

    private func dataValue(from statement: OpaquePointer, column: Int32) -> Data? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL else { return nil }
        guard let bytes = sqlite3_column_blob(statement, column) else { return nil }

        return Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, column)))
    }

    private func messageDate(from statement: OpaquePointer, column: Int32) -> Date {
        let rawValue = sqlite3_column_double(statement, column)
        let seconds = abs(rawValue) > 10_000_000_000 ? rawValue / 1_000_000_000 : rawValue

        return Date(timeIntervalSinceReferenceDate: seconds)
    }

    private func logDatabaseError(_ message: String, database: OpaquePointer) {
        logger.error("\(message, privacy: .public): \(self.errorMessage(database), privacy: .public)")
    }

    private func errorMessage(_ database: OpaquePointer?) -> String {
        guard let database, let message = sqlite3_errmsg(database) else {
            return "Unknown Messages database error"
        }

        return String(cString: message)
    }
}
