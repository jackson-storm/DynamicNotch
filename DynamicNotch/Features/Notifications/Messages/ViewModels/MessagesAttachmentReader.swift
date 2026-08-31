import Foundation
import ImageIO
import OSLog
import SQLite3
import UniformTypeIdentifiers

final class MessagesAttachmentReader {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "MessagesAttachmentReader")

    func attachments(for messageID: Int64, database: OpaquePointer) -> [MessagesAttachment] {
        let query = """
        SELECT
            a.ROWID,
            a.filename,
            a.transfer_name,
            a.mime_type,
            a.uti
        FROM message_attachment_join AS maj
        INNER JOIN attachment AS a
            ON a.ROWID = maj.attachment_id
        WHERE
            maj.message_id = ?
            AND COALESCE(a.hide_attachment, 0) = 0
        ORDER BY maj.ROWID ASC;
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            query,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            logDatabaseError(database, message: "Could not prepare Messages attachment query")
            sqlite3_finalize(statement)
            return []
        }

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_bind_int64(statement, 1, messageID) == SQLITE_OK else {
            logDatabaseError(database, message: "Could not bind Messages message RowID")
            return []
        }

        var attachments: [MessagesAttachment] = []
        var result = sqlite3_step(statement)

        while result == SQLITE_ROW {
            let rowID = sqlite3_column_int64(statement, 0)
            let filename = stringValue(from: statement, column: 1)
            let transferName = stringValue(from: statement, column: 2)
            let mimeType = stringValue(from: statement, column: 3)
            let uti = stringValue(from: statement, column: 4)

            let attachment = makeAttachment(
                rowID: rowID,
                filename: filename,
                transferName: transferName,
                mimeType: mimeType,
                uti: uti
            )

            attachments.append(attachment)
            result = sqlite3_step(statement)
        }

        guard result == SQLITE_DONE else {
            logDatabaseError(database, message: "Could not finish reading Messages attachments")
            return []
        }

        return attachments
    }

    private func makeAttachment(rowID: Int64, filename: String?, transferName: String?, mimeType: String?, uti: String?) -> MessagesAttachment {
        let fileURL = fileURL(from: filename)
        let contentType = contentType(uti: uti, mimeType: mimeType, filename: filename)
        let id = String(rowID)

        if contentType?.conforms(to: .audio) == true {
            return .audio(MessagesAudioAttachment(id: id, fileURL: fileURL, duration: nil))
        }

        if contentType?.conforms(to: .image) == true {
            let size = imageSize(fileURL)

            return .image(
                MessagesImageAttachment(
                    id: id,
                    fileURL: fileURL,
                    width: size?.width,
                    height: size?.height
                )
            )
        }

        if contentType?.conforms(to: .movie) == true || contentType?.conforms(to: .video) == true {
            return .video(MessagesVideoAttachment(id: id, fileURL: fileURL, duration: nil))
        }

        return .file(
            MessagesFileAttachment(
                id: id,
                fileURL: fileURL,
                filename: displayFilename(transferName: transferName, filename: filename, fileURL: fileURL),
                mimeType: mimeType,
                uti: uti
            )
        )
    }

    private func contentType(uti: String?, mimeType: String?, filename: String?) -> UTType? {
        if let uti = normalized(uti), let type = UTType(uti) {
            return type
        }

        if let mimeType = normalized(mimeType), let type = UTType(mimeType: mimeType) {
            return type
        }

        guard let filename = normalized(filename) else { return nil }

        let fileExtension = URL(fileURLWithPath: filename).pathExtension

        guard !fileExtension.isEmpty else { return nil }

        return UTType(filenameExtension: fileExtension)
    }

    private func fileURL(from filename: String?) -> URL? {
        guard let filename = normalized(filename) else { return nil }

        let path = (filename as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: path).standardizedFileURL

        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func displayFilename(transferName: String?, filename: String?, fileURL: URL?) -> String? {
        if let transferName = normalized(transferName) {
            return transferName
        }

        if let fileURL {
            return fileURL.lastPathComponent
        }

        guard let filename = normalized(filename) else { return nil }

        return URL(fileURLWithPath: filename).lastPathComponent
    }

    private func imageSize(_ fileURL: URL?) -> (width: Int, height: Int)? {
        guard let fileURL else { return nil }
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }
        guard let width = properties[kCGImagePropertyPixelWidth] as? NSNumber else { return nil }
        guard let height = properties[kCGImagePropertyPixelHeight] as? NSNumber else { return nil }

        return (width.intValue, height.intValue)
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }

        let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return normalizedValue.isEmpty ? nil : normalizedValue
    }

    private func stringValue(from statement: OpaquePointer?, column: Int32) -> String? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL else { return nil }
        guard let value = sqlite3_column_text(statement, column) else { return nil }

        return String(cString: value)
    }

    private func logDatabaseError(_ database: OpaquePointer?, message: String) {
        let details = database.flatMap { sqlite3_errmsg($0) }.map(String.init(cString:)) ?? "Unknown SQLite error"

        logger.error("\(message, privacy: .public): \(details, privacy: .public)")
    }
}
