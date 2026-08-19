import Foundation
import OSLog
import SQLite3

final class MailDatabaseReader {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MailDatabaseReader")
    private let databaseURLOverride: URL?
    
    init(databaseURL: URL? = nil) {
        self.databaseURLOverride = databaseURL
    }

    func latestRowID() -> Int64? {
        inDatabase { database in
            let query = """
            SELECT MAX(ROWID)
            FROM messages
            WHERE deleted = 0;
            """

            return inStatement(
                database: database,
                query: query,
                errorMessage: "Could not prepare latest RowID query"
            ) { statement in
                
                guard sqlite3_step(statement) == SQLITE_ROW else {
                    logDatabaseError(database, message: "Could not read latest RowID")
                    return nil
                }

                guard sqlite3_column_type(statement, 0) != SQLITE_NULL else {
                    return 0
                }

                return sqlite3_column_int64(statement, 0)
            }
        }
    }

    func messages(after rowID: Int64) -> [MailMessage] {
        inDatabase { database in
            let query = """
            SELECT
                m.ROWID,
                mgd.message_id_header,
                m.date_received,
                a.address,
                s.subject,
                sm.summary
            FROM messages AS m
            INNER JOIN mailboxes AS mb
                ON mb.ROWID = m.mailbox
            LEFT JOIN message_global_data AS mgd
                ON mgd.ROWID = m.global_message_id
            LEFT JOIN addresses AS a
                ON a.ROWID = m.sender
            LEFT JOIN subjects AS s
                ON s.ROWID = m.subject
            LEFT JOIN summaries AS sm
                ON sm.ROWID = m.summary
            WHERE
                m.ROWID > ?
                AND m.deleted = 0
                AND LOWER(RTRIM(mb.url, '/')) LIKE '%/inbox'
            ORDER BY m.ROWID ASC;
            """

            return inStatement(
                database: database,
                query: query,
                errorMessage: "Could not prepare messages query"
            ) { statement in
                
                guard sqlite3_bind_int64(statement, 1, rowID) == SQLITE_OK else {
                    logDatabaseError(database, message: "Could not bind the last processed RowID")
                    return nil
                }

                var messages: [MailMessage] = []
                var result = sqlite3_step(statement)

                while result == SQLITE_ROW {
                    let messageRowID = sqlite3_column_int64(statement, 0)
                    let messageIDHeader = stringValue(from: statement, column: 1) ?? ""
                    let receivedTimestamp = sqlite3_column_int64(statement, 2)
                    let sender = stringValue(from: statement, column: 3) ?? ""
                    let subject = stringValue(from: statement, column: 4) ?? ""
                    let summary = stringValue(from: statement, column: 5)

                    let message = MailMessage(
                        rowID: messageRowID,
                        messageIDHeader: messageIDHeader,
                        sender: sender,
                        subject: subject,
                        summary: summary,
                        receivedDate: Date(timeIntervalSince1970: TimeInterval(receivedTimestamp))
                    )
                    messages.append(message)
                    result = sqlite3_step(statement)
                }

                guard result == SQLITE_DONE else {
                    logDatabaseError(database, message: "Could not finish reading messages")
                    return nil
                }

                return messages
            }
        } ?? []
    }

    func message(withRowID rowID: Int64) -> MailMessage? {
        let query = """
        SELECT
            m.ROWID,
            mgd.message_id_header,
            m.date_received,
            a.address,
            s.subject,
            sm.summary
        FROM messages AS m
        INNER JOIN mailboxes AS mb
            ON mb.ROWID = m.mailbox
        LEFT JOIN message_global_data AS mgd
            ON mgd.ROWID = m.global_message_id
        LEFT JOIN addresses AS a
            ON a.ROWID = m.sender
        LEFT JOIN subjects AS s
            ON s.ROWID = m.subject
        LEFT JOIN summaries AS sm
            ON sm.ROWID = m.summary
        WHERE
            m.ROWID = ?
            AND m.deleted = 0
            AND LOWER(RTRIM(mb.url, '/')) LIKE '%/inbox'
        LIMIT 1;
        """

        return inDatabase { database in
            inStatement(
                database: database,
                query: query,
                errorMessage: "Failed to prepare Mail message query"
            ) { statement in
                guard sqlite3_bind_int64(statement, 1, rowID) == SQLITE_OK else {
                    logDatabaseError(database, message: "Could not bind Mail message RowID")
                    return nil
                }

                guard sqlite3_step(statement) == SQLITE_ROW else { return nil }

                let messageRowID = sqlite3_column_int64(statement, 0)
                let messageIDHeader = stringValue(from: statement, column: 1) ?? ""
                let receivedTimestamp = sqlite3_column_int64(statement, 2)
                let sender = stringValue(from: statement, column: 3) ?? ""
                let subject = stringValue(from: statement, column: 4) ?? ""
                let summary = stringValue(from: statement, column: 5)

                return MailMessage(
                    rowID: messageRowID,
                    messageIDHeader: messageIDHeader,
                    sender: sender,
                    subject: subject,
                    summary: summary,
                    receivedDate: Date(
                        timeIntervalSince1970: TimeInterval(receivedTimestamp)
                    )
                )
            }
        }
    }

    func databaseURL() -> URL? {
        if let databaseURLOverride {
            guard FileManager.default.fileExists(atPath: databaseURLOverride.path) else { return nil }

            return databaseURLOverride
        }
        
        let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mail", isDirectory: true)

        guard let versions = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return nil }

        let latestVersion = versions.filter { $0.lastPathComponent.hasPrefix("V") }
                                    .max {
                                        let lhs = Int($0.lastPathComponent.dropFirst()) ?? 0
                                        let rhs = Int($1.lastPathComponent.dropFirst()) ?? 0
                                        return lhs < rhs
                                    }

        guard let latestVersion else { return nil }

        let databaseURL = latestVersion.appendingPathComponent("MailData").appendingPathComponent("Envelope Index")

        guard FileManager.default.fileExists(atPath: databaseURL.path) else { return nil }

        return databaseURL
    }

    private func inDatabase<T>(_ operation: (OpaquePointer) -> T?) -> T? {
        guard let databaseURL = databaseURL() else {
            logger.error("Mail database was not found")
            return nil
        }

        var database: OpaquePointer?

        guard sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let database else {
            logDatabaseError(database, message: "Could not open Mail database")
            sqlite3_close(database)
            return nil
        }

        defer {
            sqlite3_close(database)
        }

        sqlite3_busy_timeout(database, 1_000)

        return operation(database)
    }

    private func inStatement<T>(database: OpaquePointer, query: String, errorMessage: String, operation: (OpaquePointer) -> T?) -> T? {
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            logDatabaseError(database, message: errorMessage)
            sqlite3_finalize(statement)
            return nil
        }

        defer {
            sqlite3_finalize(statement)
        }

        return operation(statement)
    }

    private func stringValue(from statement: OpaquePointer?, column: Int32) -> String? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL,
              let value = sqlite3_column_text(statement, column) else {
            return nil
        }

        return String(cString: value)
    }

    private func logDatabaseError(_ database: OpaquePointer?, message: String) {
        let details = database.flatMap { sqlite3_errmsg($0) }.map(String.init(cString:)) ?? "Unknown SQLite error"
        logger.error("\(message, privacy: .public): \(details, privacy: .public)")
    }
}
