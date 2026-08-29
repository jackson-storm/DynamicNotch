import Foundation
import OSLog
import SQLite3
import Contacts

final class MessagesDatabaseReader {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MessagesDatabaseReader")
    private let databaseURLOverride: URL?
    private let contactStore = CNContactStore()
    private var contactCache: [String: String] = [:]

    init(databaseURL: URL? = nil) {
        self.databaseURLOverride = databaseURL
    }

    func latestRowID() -> Int64? {
        inDatabase { database in
            let query = """
            SELECT MAX(ROWID)
            FROM message
            WHERE is_from_me = 0;
            """

            return inStatement(
                database: database,
                query: query,
                errorMessage: "Could not prepare latest Messages RowID query"
            ) { statement in
                guard sqlite3_step(statement) == SQLITE_ROW else {
                    logDatabaseError(database, message: "Could not read latest Messages RowID")
                    return nil
                }

                guard sqlite3_column_type(statement, 0) != SQLITE_NULL else {
                    return 0
                }

                return sqlite3_column_int64(statement, 0)
            }
        }
    }

    func messages(after rowID: Int64) -> [MessagesMessage] {
        inDatabase { database in
            let query = """
            SELECT
                m.ROWID,
                COALESCE(m.guid, ''),
                m.text,
                m.attributedBody,
                m.date,
                COALESCE(h.id, ''),
                m.is_from_me,
                COALESCE(c.display_name, '')
            FROM message AS m
            LEFT JOIN handle AS h ON h.ROWID = m.handle_id
            LEFT JOIN chat_message_join AS cmj ON cmj.message_id = m.ROWID
            LEFT JOIN chat AS c ON c.ROWID = cmj.chat_id
            WHERE
                m.ROWID > ?
                AND m.is_from_me = 0
            ORDER BY m.ROWID ASC;
            """

            return inStatement(
                database: database,
                query: query,
                errorMessage: "Could not prepare Messages query"
            ) { statement in
                guard sqlite3_bind_int64(statement, 1, rowID) == SQLITE_OK else {
                    logDatabaseError(database, message: "Could not bind the last processed Messages RowID")
                    return nil
                }

                var messages: [MessagesMessage] = []
                var result = sqlite3_step(statement)

                while result == SQLITE_ROW {
                    let messageRowID = sqlite3_column_int64(statement, 0)
                    let guid = stringValue(from: statement, column: 1) ?? ""
                    let handleID = stringValue(from: statement, column: 5) ?? ""
                    let isFromMe = sqlite3_column_int(statement, 6) != 0
                    let chatDisplayName = stringValue(from: statement, column: 7) ?? ""

                    let text = extractMessageText(from: statement, textColumn: 2, attributedColumn: 3)
                    let receivedDate = extractDate(from: statement, column: 4)

                    let resolvedSender: String
                    if !chatDisplayName.isEmpty {
                        resolvedSender = chatDisplayName
                    } else {
                        resolvedSender = resolveContactName(for: handleID)
                    }

                    // Only add if there is readable content
                    if !text.isEmpty {
                        let message = MessagesMessage(
                            rowID: messageRowID,
                            guid: guid,
                            sender: resolvedSender,
                            senderHandle: handleID,
                            text: text,
                            receivedDate: receivedDate,
                            isFromMe: isFromMe
                        )
                        messages.append(message)
                    }

                    result = sqlite3_step(statement)
                }

                guard result == SQLITE_DONE else {
                    logDatabaseError(database, message: "Could not finish reading Messages")
                    return nil
                }

                return messages
            }
        } ?? []
    }

    func message(withRowID rowID: Int64) -> MessagesMessage? {
        let query = """
        SELECT
            m.ROWID,
            COALESCE(m.guid, ''),
            m.text,
            m.attributedBody,
            m.date,
            COALESCE(h.id, ''),
            m.is_from_me,
            COALESCE(c.display_name, '')
        FROM message AS m
        LEFT JOIN handle AS h ON h.ROWID = m.handle_id
        LEFT JOIN chat_message_join AS cmj ON cmj.message_id = m.ROWID
        LEFT JOIN chat AS c ON c.ROWID = cmj.chat_id
        WHERE
            m.ROWID = ?
            AND m.is_from_me = 0
        LIMIT 1;
        """

        return inDatabase { database in
            inStatement(
                database: database,
                query: query,
                errorMessage: "Failed to prepare single Message query"
            ) { statement in
                guard sqlite3_bind_int64(statement, 1, rowID) == SQLITE_OK else {
                    logDatabaseError(database, message: "Could not bind Message RowID")
                    return nil
                }

                guard sqlite3_step(statement) == SQLITE_ROW else { return nil }

                let messageRowID = sqlite3_column_int64(statement, 0)
                let guid = stringValue(from: statement, column: 1) ?? ""
                let handleID = stringValue(from: statement, column: 5) ?? ""
                let isFromMe = sqlite3_column_int(statement, 6) != 0
                let chatDisplayName = stringValue(from: statement, column: 7) ?? ""

                let text = extractMessageText(from: statement, textColumn: 2, attributedColumn: 3)
                let receivedDate = extractDate(from: statement, column: 4)

                let resolvedSender: String
                if !chatDisplayName.isEmpty {
                    resolvedSender = chatDisplayName
                } else {
                    resolvedSender = resolveContactName(for: handleID)
                }

                return MessagesMessage(
                    rowID: messageRowID,
                    guid: guid,
                    sender: resolvedSender,
                    senderHandle: handleID,
                    text: text,
                    receivedDate: receivedDate,
                    isFromMe: isFromMe
                )
            }
        }
    }

    func databaseURL() -> URL? {
        if let databaseURLOverride {
            guard FileManager.default.fileExists(atPath: databaseURLOverride.path) else { return nil }
            return databaseURLOverride
        }

        let databaseURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Messages", isDirectory: true)
            .appendingPathComponent("chat.db")

        guard FileManager.default.fileExists(atPath: databaseURL.path) else { return nil }

        return databaseURL
    }

    private func extractMessageText(from statement: OpaquePointer?, textColumn: Int32, attributedColumn: Int32) -> String {
        if let directText = stringValue(from: statement, column: textColumn),
           !directText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return directText
        }

        if let data = dataValue(from: statement, column: attributedColumn) {
            if let decoded = extractTextFromAttributedBody(data),
               !decoded.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return decoded
            }
        }

        return ""
    }

    private func extractTextFromAttributedBody(_ data: Data) -> String? {
        if let attr = try? NSKeyedUnarchiver.unarchivedObject(
            ofClasses: [NSAttributedString.self, NSMutableAttributedString.self, NSString.self],
            from: data
        ) as? NSAttributedString {
            return attr.string
        }

        // Fallback: search for NSString content in typedstream buffer
        return extractPlainTextFromTypedStream(data)
    }

    private func extractPlainTextFromTypedStream(_ data: Data) -> String? {
        // Look for the "NSString" marker in typedstream
        guard let markerRange = data.range(of: Data("NSString".utf8)) else {
            return nil
        }

        let searchStartIndex = markerRange.upperBound
        guard searchStartIndex < data.count else { return nil }

        let subdata = data.subdata(in: searchStartIndex..<data.count)

        // Find printable UTF-8 sequences
        var result = ""
        var currentBytes: [UInt8] = []

        for byte in subdata {
            if byte >= 0x20 && byte <= 0x7E || byte >= 0xC0 {
                currentBytes.append(byte)
            } else if !currentBytes.isEmpty {
                if let str = String(bytes: currentBytes, encoding: .utf8), str.count >= 2 {
                    if str.count > result.count {
                        result = str
                    }
                }
                currentBytes.removeAll(keepingCapacity: true)
            }
        }

        if !currentBytes.isEmpty, let str = String(bytes: currentBytes, encoding: .utf8), str.count > result.count {
            result = str
        }

        return result.isEmpty ? nil : result
    }

    private func extractDate(from statement: OpaquePointer?, column: Int32) -> Date {
        let rawDate = sqlite3_column_int64(statement, column)
        let appleEpochOffset: TimeInterval = 978307200 // 2001-01-01 00:00:00 UTC

        let timestamp: TimeInterval
        if rawDate > 10_000_000_000_000_000 { // nanoseconds (macOS 10.13+)
            timestamp = Double(rawDate) / 1_000_000_000 + appleEpochOffset
        } else if rawDate > 10_000_000_000 { // microseconds
            timestamp = Double(rawDate) / 1_000_000 + appleEpochOffset
        } else if rawDate > 0 { // seconds
            timestamp = Double(rawDate) + appleEpochOffset
        } else {
            timestamp = Date().timeIntervalSince1970
        }

        return Date(timeIntervalSince1970: timestamp)
    }

    private func resolveContactName(for handle: String) -> String {
        guard !handle.isEmpty else { return "Unknown" }

        if let cached = contactCache[handle] {
            return cached
        }

        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            return handle
        }

        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]

        let predicate: NSPredicate
        if handle.contains("@") {
            predicate = CNContact.predicateForContacts(matchingEmailAddress: handle)
        } else {
            predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: handle))
        }

        if let contacts = try? contactStore.unifiedContacts(matching: predicate, keysToFetch: keys),
           let contact = contacts.first {
            let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
            if !fullName.isEmpty {
                contactCache[handle] = fullName
                return fullName
            }
        }

        contactCache[handle] = handle
        return handle
    }

    private func inDatabase<T>(_ operation: (OpaquePointer) -> T?) -> T? {
        guard let databaseURL = databaseURL() else {
            logger.error("Messages database was not found")
            return nil
        }

        var database: OpaquePointer?

        guard sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let database else {
            logDatabaseError(database, message: "Could not open Messages database")
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

    private func dataValue(from statement: OpaquePointer?, column: Int32) -> Data? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL,
              let bytes = sqlite3_column_blob(statement, column) else {
            return nil
        }

        let length = sqlite3_column_bytes(statement, column)
        return Data(bytes: bytes, count: Int(length))
    }

    private func logDatabaseError(_ database: OpaquePointer?, message: String) {
        let details = database.flatMap { sqlite3_errmsg($0) }.map(String.init(cString:)) ?? "Unknown SQLite error"
        logger.error("\(message, privacy: .public): \(details, privacy: .public)")
    }
}
