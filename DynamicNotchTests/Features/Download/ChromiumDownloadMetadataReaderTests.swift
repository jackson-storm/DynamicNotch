//
//  ChromiumDownloadMetadataReaderTests.swift
//  DynamicNotchTests
//

import XCTest
import SQLite3
@testable import DynamicNotch

final class ChromiumDownloadMetadataReaderTests: XCTestCase {

    func testQueriesTotalBytesAndTargetPathFromChromiumHistory() throws {
        let tempDir = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dbURL = tempDir.appendingPathComponent("History")
        try createChromiumDownloadsDatabase(at: dbURL)

        let crdownloadPath = tempDir.appendingPathComponent("10GB.bin.crdownload").path
        let targetPath = tempDir.appendingPathComponent("10GB.bin").path
        let expectedTotal: Int64 = 10_737_418_240 // 10 GB

        try insertDownloadRow(
            in: dbURL,
            currentPath: crdownloadPath,
            targetPath: targetPath,
            receivedBytes: 1_800_000_000,
            totalBytes: expectedTotal,
            state: 0
        )

        let reader = ChromiumDownloadMetadataReader(explicitDatabaseURLs: [dbURL])
        let info = reader.downloadInfo(for: URL(fileURLWithPath: crdownloadPath))

        XCTAssertNotNil(info)
        XCTAssertEqual(info?.totalBytes, expectedTotal)
        XCTAssertEqual(info?.targetPath, targetPath)
    }

    func testMatchesByTargetPathIfCurrentPathDiffers() throws {
        let tempDir = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dbURL = tempDir.appendingPathComponent("History")
        try createChromiumDownloadsDatabase(at: dbURL)

        let crdownloadPath = tempDir.appendingPathComponent("installer.dmg.crdownload").path
        let targetPath = tempDir.appendingPathComponent("installer.dmg").path
        let expectedTotal: Int64 = 500_000_000

        try insertDownloadRow(
            in: dbURL,
            currentPath: "/some/other/temp/path.crdownload",
            targetPath: targetPath,
            receivedBytes: 50_000_000,
            totalBytes: expectedTotal,
            state: 0
        )

        let reader = ChromiumDownloadMetadataReader(explicitDatabaseURLs: [dbURL])
        let info = reader.downloadInfo(for: URL(fileURLWithPath: crdownloadPath))

        XCTAssertNotNil(info)
        XCTAssertEqual(info?.totalBytes, expectedTotal)
        XCTAssertEqual(info?.targetPath, targetPath)
    }

    func testReturnsNilWhenDownloadNotFoundOrTotalBytesZero() throws {
        let tempDir = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dbURL = tempDir.appendingPathComponent("History")
        try createChromiumDownloadsDatabase(at: dbURL)

        let reader = ChromiumDownloadMetadataReader(explicitDatabaseURLs: [dbURL])
        let info = reader.downloadInfo(for: URL(fileURLWithPath: "/nonexistent/file.crdownload"))

        XCTAssertNil(info)
    }

    func testFolderFileDownloadMonitorCalculatesExactProgressUsingChromiumMetadata() {
        let tempDir = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dbURL = tempDir.appendingPathComponent("History")
        try? createChromiumDownloadsDatabase(at: dbURL)

        let crdownloadURL = tempDir.appendingPathComponent("dataset.zip.crdownload")
        let targetPath = tempDir.appendingPathComponent("dataset.zip").path
        let totalBytes: Int64 = 100_000
        let currentBytes = 25_000

        try? insertDownloadRow(
            in: dbURL,
            currentPath: crdownloadURL.path,
            targetPath: targetPath,
            receivedBytes: Int64(currentBytes),
            totalBytes: totalBytes,
            state: 0
        )

        FileManager.default.createFile(
            atPath: crdownloadURL.path,
            contents: Data(repeating: 0xCC, count: currentBytes)
        )

        let reader = ChromiumDownloadMetadataReader(explicitDatabaseURLs: [dbURL])
        let monitor = FolderFileDownloadMonitor(
            monitoredDirectories: [tempDir],
            chromiumReader: reader
        )

        let expectation = expectation(description: "publishes exact chromium download progress")

        monitor.onSnapshotChange = { transfers in
            guard let transfer = transfers.first else { return }
            XCTAssertEqual(transfer.displayName, "dataset.zip")
            XCTAssertEqual(transfer.estimatedTotalByteCount, totalBytes)
            XCTAssertEqual(transfer.byteCount, Int64(currentBytes))
            // 25,000 / 100,000 = 0.25 (25%)
            XCTAssertEqual(transfer.progress, 0.25, accuracy: 0.001)
            expectation.fulfill()
        }

        monitor.startMonitoring()
        wait(for: [expectation], timeout: 3.0)
        monitor.stopMonitoring()
    }
}

private extension ChromiumDownloadMetadataReaderTests {
    func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func createChromiumDownloadsDatabase(at url: URL) throws {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK, let db else {
            throw XCTSkip("Failed to create SQLite DB")
        }
        defer { sqlite3_close(db) }

        let schema = """
        CREATE TABLE downloads (
            id INTEGER PRIMARY KEY,
            guid VARCHAR NOT NULL,
            current_path LONGVARCHAR NOT NULL,
            target_path LONGVARCHAR NOT NULL,
            start_time INTEGER NOT NULL,
            received_bytes INTEGER NOT NULL,
            total_bytes INTEGER NOT NULL,
            state INTEGER NOT NULL
        );
        """
        XCTAssertEqual(sqlite3_exec(db, schema, nil, nil, nil), SQLITE_OK)
    }

    func insertDownloadRow(
        in databaseURL: URL,
        currentPath: String,
        targetPath: String,
        receivedBytes: Int64,
        totalBytes: Int64,
        state: Int32
    ) throws {
        var db: OpaquePointer?
        guard sqlite3_open(databaseURL.path, &db) == SQLITE_OK, let db else {
            throw XCTSkip("Failed to open SQLite DB")
        }
        defer { sqlite3_close(db) }

        let insert = """
        INSERT INTO downloads (guid, current_path, target_path, start_time, received_bytes, total_bytes, state)
        VALUES ('guid-123', ?, ?, 1330000000, ?, ?, ?);
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insert, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            XCTFail("Failed to prepare insert")
            return
        }
        defer { sqlite3_finalize(stmt) }

        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, 1, currentPath, -1, transient)
        sqlite3_bind_text(stmt, 2, targetPath, -1, transient)
        sqlite3_bind_int64(stmt, 3, receivedBytes)
        sqlite3_bind_int64(stmt, 4, totalBytes)
        sqlite3_bind_int(stmt, 5, state)

        XCTAssertEqual(sqlite3_step(stmt), SQLITE_DONE)
    }
}
