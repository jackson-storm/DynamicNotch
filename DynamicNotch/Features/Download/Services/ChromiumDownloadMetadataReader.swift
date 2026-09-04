//
//  ChromiumDownloadMetadataReader.swift
//  DynamicNotch
//

import Foundation
import OSLog
import SQLite3

struct ChromiumDownloadInfo: Equatable, Sendable {
    let totalBytes: Int64
    let targetPath: String?
}

nonisolated final class ChromiumDownloadMetadataReader: @unchecked Sendable {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DynamicNotch", category: "ChromiumDownloadMetadataReader")
    private let fileManager: FileManager
    private let appSupportURL: URL
    private let explicitDatabaseURLs: [URL]?

    private let lock = NSLock()
    private var cachedDatabaseURLs: [URL]?
    private var lastCacheRefresh: Date = .distantPast
    private let cacheTTL: TimeInterval = 30.0

    private static let candidateBrowserSubpaths: [String] = [
        "net.imput.helium",
        "Google/Chrome",
        "Google/Chrome Canary",
        "Google/Chrome Beta",
        "Google/Chrome Dev",
        "Chromium",
        "BraveSoftware/Brave-Browser",
        "BraveSoftware/Brave-Browser-Beta",
        "BraveSoftware/Brave-Browser-Nightly",
        "Microsoft Edge",
        "Microsoft Edge Canary",
        "Microsoft Edge Beta",
        "Microsoft Edge Dev",
        "Arc/User Data",
        "Vivaldi",
        "com.operasoftware.Opera",
        "com.operasoftware.OperaGX",
        "Yandex/YandexBrowser"
    ]

    init(
        fileManager: FileManager = .default,
        appSupportURL: URL? = nil,
        explicitDatabaseURLs: [URL]? = nil
    ) {
        self.fileManager = fileManager
        self.explicitDatabaseURLs = explicitDatabaseURLs
        self.appSupportURL = appSupportURL
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
    }

    /// Looks up download metadata (total file size and target path) for the given file URL
    /// across installed Chromium-based browsers.
    func downloadInfo(for fileURL: URL) -> ChromiumDownloadInfo? {
        let databases = resolvedDatabaseURLs()
        guard !databases.isEmpty else { return nil }

        let currentPath = fileURL.standardizedFileURL.path
        let targetPath = fileURL.deletingPathExtension().standardizedFileURL.path

        for databaseURL in databases {
            if let info = queryDownload(in: databaseURL, currentPath: currentPath, targetPath: targetPath) {
                return info
            }
        }

        return nil
    }

    private func resolvedDatabaseURLs() -> [URL] {
        if let explicit = explicitDatabaseURLs {
            return explicit
        }

        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        if let cached = cachedDatabaseURLs, now.timeIntervalSince(lastCacheRefresh) < cacheTTL {
            return cached
        }

        let discovered = discoverDatabaseURLs()
        cachedDatabaseURLs = discovered
        lastCacheRefresh = now
        return discovered
    }

    private func discoverDatabaseURLs() -> [URL] {
        var result: [URL] = []

        for subpath in Self.candidateBrowserSubpaths {
            let browserDir = appSupportURL.appendingPathComponent(subpath)
            guard fileManager.fileExists(atPath: browserDir.path) else { continue }

            // Check direct History (e.g. Opera)
            let directHistory = browserDir.appendingPathComponent("History")
            if fileManager.fileExists(atPath: directHistory.path) {
                result.append(directHistory)
            }

            // Check profiles (Default, Profile 1, Profile 2, etc.)
            if let subdirs = try? fileManager.contentsOfDirectory(
                at: browserDir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                for subdir in subdirs {
                    let profileHistory = subdir.appendingPathComponent("History")
                    if fileManager.fileExists(atPath: profileHistory.path) {
                        result.append(profileHistory)
                    }
                }
            }
        }

        return result
    }

    private func queryDownload(
        in databaseURL: URL,
        currentPath: String,
        targetPath: String
    ) -> ChromiumDownloadInfo? {
        var database: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_URI
        let uriPath = "file://\(databaseURL.path)?mode=ro"

        guard sqlite3_open_v2(uriPath, &database, flags, nil) == SQLITE_OK,
              let database else {
            if let database { sqlite3_close(database) }
            return nil
        }

        defer {
            sqlite3_close(database)
        }

        sqlite3_busy_timeout(database, 200)

        let query = """
        SELECT total_bytes, target_path
        FROM downloads
        WHERE current_path = ? OR target_path = ? OR current_path = ? OR target_path = ?
        ORDER BY start_time DESC
        LIMIT 1;
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            if let statement { sqlite3_finalize(statement) }
            return nil
        }

        defer {
            sqlite3_finalize(statement)
        }

        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, currentPath, -1, transient)
        sqlite3_bind_text(statement, 2, targetPath, -1, transient)
        sqlite3_bind_text(statement, 3, targetPath, -1, transient)
        sqlite3_bind_text(statement, 4, currentPath, -1, transient)

        guard sqlite3_step(statement) == SQLITE_ROW else {
            return nil
        }

        let totalBytes = sqlite3_column_int64(statement, 0)
        let resolvedTargetPath: String? = {
            guard sqlite3_column_type(statement, 1) != SQLITE_NULL,
                  let cString = sqlite3_column_text(statement, 1) else {
                return nil
            }
            return String(cString: cString)
        }()

        guard totalBytes > 0 else {
            return nil
        }

        return ChromiumDownloadInfo(totalBytes: totalBytes, targetPath: resolvedTargetPath)
    }
}
