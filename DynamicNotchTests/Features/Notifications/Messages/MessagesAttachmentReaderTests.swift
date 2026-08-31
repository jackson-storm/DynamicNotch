import AppKit
import SQLite3
import XCTest
@testable import DynamicNotch

@MainActor
final class MessagesAttachmentReaderTests: XCTestCase {

    func testAttachmentsReturnsEmptyArrayWhenMessageHasNoAttachments() throws {
        let database = try makeDatabase()

        try database.insertMessage(rowID: 1)

        let attachments = try readAttachments(for: 1, in: database)

        XCTAssertTrue(attachments.isEmpty)
    }

    func testAttachmentsPreservesJoinOrderAndExcludesHiddenAttachments() throws {
        let database = try makeDatabase()
        let firstURL = try database.createFile(named: "first.pdf")
        let secondURL = try database.createFile(named: "second.pdf")
        let hiddenURL = try database.createFile(named: "hidden.pdf")

        try database.insertMessage(rowID: 1)

        try database.insertAttachment(
            rowID: 100,
            filename: firstURL.path,
            transferName: "First.pdf",
            mimeType: "application/pdf",
            uti: "com.adobe.pdf"
        )

        try database.insertAttachment(
            rowID: 200,
            filename: secondURL.path,
            transferName: "Second.pdf",
            mimeType: "application/pdf",
            uti: "com.adobe.pdf"
        )

        try database.insertAttachment(
            rowID: 300,
            filename: hiddenURL.path,
            transferName: "Hidden.pdf",
            mimeType: "application/pdf",
            uti: "com.adobe.pdf",
            isHidden: true
        )

        try database.linkAttachment(rowID: 30, messageID: 1, attachmentID: 100)
        try database.linkAttachment(rowID: 10, messageID: 1, attachmentID: 200)
        try database.linkAttachment(rowID: 20, messageID: 1, attachmentID: 300)

        let attachments = try readAttachments(for: 1, in: database)

        XCTAssertEqual(attachments.map(\.id), ["200", "100"])
    }

    func testImageAttachmentUsesUTIAndReadsPixelDimensions() throws {
        let database = try makeDatabase()
        let imageData = try pngData(width: 38, height: 30)
        let imageURL = try database.createFile(named: "photo.bin", data: imageData)

        try database.insertMessage(rowID: 1)

        try database.insertAttachment(
            rowID: 100,
            filename: imageURL.path,
            transferName: "Photo.png",
            mimeType: "video/quicktime",
            uti: "public.png"
        )

        try database.linkAttachment(rowID: 1, messageID: 1, attachmentID: 100)

        let attachments = try readAttachments(for: 1, in: database)

        XCTAssertEqual(
            attachments,
            [
                .image(
                    MessagesImageAttachment(
                        id: "100",
                        fileURL: imageURL.standardizedFileURL,
                        width: 38,
                        height: 30
                    )
                )
            ]
        )
    }

    func testAudioAttachmentUsesMIMETypeWhenUTIIsUnavailable() throws {
        let database = try makeDatabase()
        let audioURL = try database.createFile(named: "recording.data", data: Data([0]))

        try database.insertMessage(rowID: 1)

        try database.insertAttachment(
            rowID: 100,
            filename: audioURL.path,
            transferName: "Recording.mp3",
            mimeType: "audio/mpeg",
            uti: nil
        )

        try database.linkAttachment(rowID: 1, messageID: 1, attachmentID: 100)

        let attachments = try readAttachments(for: 1, in: database)

        XCTAssertEqual(
            attachments,
            [
                .audio(
                    MessagesAudioAttachment(
                        id: "100",
                        fileURL: audioURL.standardizedFileURL,
                        duration: nil
                    )
                )
            ]
        )
    }

    func testVideoAttachmentUsesFilenameExtensionWhenMetadataIsUnavailable() throws {
        let database = try makeDatabase()
        let videoURL = try database.createFile(named: "preview.mov", data: Data([0]))

        try database.insertMessage(rowID: 1)

        try database.insertAttachment(
            rowID: 100,
            filename: videoURL.path,
            transferName: "Preview.mov",
            mimeType: nil,
            uti: nil
        )

        try database.linkAttachment(rowID: 1, messageID: 1, attachmentID: 100)

        let attachments = try readAttachments(for: 1, in: database)

        XCTAssertEqual(
            attachments,
            [
                .video(
                    MessagesVideoAttachment(
                        id: "100",
                        fileURL: videoURL.standardizedFileURL,
                        duration: nil
                    )
                )
            ]
        )
    }

    func testFileAttachmentKeepsMetadataAndUsesTransferName() throws {
        let database = try makeDatabase()
        let fileURL = try database.createFile(named: "payload.bin", data: Data([0]))

        try database.insertMessage(rowID: 1)

        try database.insertAttachment(
            rowID: 100,
            filename: fileURL.path,
            transferName: "  Document.pdf  ",
            mimeType: "application/pdf",
            uti: "com.adobe.pdf"
        )

        try database.linkAttachment(rowID: 1, messageID: 1, attachmentID: 100)

        let attachments = try readAttachments(for: 1, in: database)

        XCTAssertEqual(
            attachments,
            [
                .file(
                    MessagesFileAttachment(
                        id: "100",
                        fileURL: fileURL.standardizedFileURL,
                        filename: "Document.pdf",
                        mimeType: "application/pdf",
                        uti: "com.adobe.pdf"
                    )
                )
            ]
        )
    }

    func testMissingFileKeepsAttachmentAndFallsBackToStoredFilename() throws {
        let database = try makeDatabase()
        let missingURL = database.url.deletingLastPathComponent().appendingPathComponent("missing-file.pdf")

        try database.insertMessage(rowID: 1)

        try database.insertAttachment(
            rowID: 100,
            filename: missingURL.path,
            transferName: " \n ",
            mimeType: nil,
            uti: nil
        )

        try database.linkAttachment(rowID: 1, messageID: 1, attachmentID: 100)

        let attachments = try readAttachments(for: 1, in: database)

        XCTAssertEqual(
            attachments,
            [
                .file(
                    MessagesFileAttachment(
                        id: "100",
                        fileURL: nil,
                        filename: "missing-file.pdf",
                        mimeType: nil,
                        uti: nil
                    )
                )
            ]
        )
    }

    func testAttachmentsReturnsEmptyArrayWhenSchemaIsUnavailable() throws {
        let database = try MessagesTestDatabase()

        let attachments = try readAttachments(for: 1, in: database)

        XCTAssertTrue(attachments.isEmpty)
    }

    private func makeDatabase() throws -> MessagesTestDatabase {
        let database = try MessagesTestDatabase()

        try database.createSchema()

        return database
    }

    private func readAttachments(for messageID: Int64, in database: MessagesTestDatabase) throws -> [MessagesAttachment] {
        var connection: OpaquePointer?

        let result = sqlite3_open_v2(
            database.url.path,
            &connection,
            SQLITE_OPEN_READONLY,
            nil
        )

        guard result == SQLITE_OK, let connection else {
            sqlite3_close(connection)
            throw MessagesAttachmentReaderTestError.databaseOpenFailed
        }

        defer {
            sqlite3_close(connection)
        }

        return MessagesAttachmentReader().attachments(for: messageID, database: connection)
    }

    private func pngData(width: Int, height: Int) throws -> Data {
        let size = CGSize(width: CGFloat(width), height: CGFloat(height))

        let representation = try XCTUnwrap(
            NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: width,
                pixelsHigh: height,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        )

        let context = try XCTUnwrap(NSGraphicsContext(bitmapImageRep: representation))

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        NSGraphicsContext.restoreGraphicsState()

        return try XCTUnwrap(representation.representation(using: .png, properties: [:]))
    }
}

private enum MessagesAttachmentReaderTestError: Error {
    case databaseOpenFailed
}
