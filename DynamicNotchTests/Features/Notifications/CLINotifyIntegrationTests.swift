import NotificationContract
import XCTest
@testable import DynamicNotch

/// Seam 2 (the king test): drives the *built* `dynamicnotch` binary end-to-end. The CLI drops
/// into a temp inbox (via `$DYNAMICNOTCH_INBOX`), then the **real** `NotificationInboxMonitor`
/// ingests it and the expected payload surfaces via `onPayload` — exactly the production path a
/// script exercises. Because an executable target's symbols aren't importable, the CLI's core
/// (`NotifyCore`) is covered transitively here rather than by an isolated unit test. Mirrors
/// `NotificationInboxMonitorIntegrationTests`.
final class CLINotifyIntegrationTests: XCTestCase {
    func testCLIDropIsUniqueNonDotfileThenRealMonitorIngestsIt() throws {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let status = try runCLI(
            ["notify",
             "--title", "Backup nightly",
             "--summary", "42 files\nOK",
             "--level", "success",
             "--source", "backup.sh",
             "--icon", "externaldrive.badge.checkmark"],
            inbox: inbox
        )
        XCTAssertEqual(status, 0)

        // Proof of atomic, collision-free drop: exactly one eligible file, named `<uuid>.json`,
        // never a lingering `.`-prefixed temp.
        let dropped = eligibleJSONFiles(in: inbox)
        XCTAssertEqual(dropped.count, 1)
        let name = try XCTUnwrap(dropped.first?.lastPathComponent)
        XCTAssertFalse(name.hasPrefix("."))
        XCTAssertTrue(name.hasSuffix(".json"))
        XCTAssertNotNil(UUID(uuidString: (name as NSString).deletingPathExtension))

        // The real monitor ingests it and hands back the payload the script authored.
        let received = try ingestSingleDrop(from: inbox)
        XCTAssertEqual(received.title, "Backup nightly")
        XCTAssertEqual(received.summary, "42 files\nOK")
        XCTAssertEqual(received.level, .success)
        XCTAssertEqual(received.source, "backup.sh")
        XCTAssertEqual(received.icon, "externaldrive.badge.checkmark")
        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)
    }

    func testSummaryFromStdinIsIngested() throws {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        // No `--summary`: the whole of stdin becomes the body.
        let status = try runCLI(
            ["notify", "--title", "From a pipe"],
            stdin: "piped body\nsecond line",
            inbox: inbox
        )
        XCTAssertEqual(status, 0)

        let received = try ingestSingleDrop(from: inbox)
        XCTAssertEqual(received.title, "From a pipe")
        XCTAssertEqual(received.summary, "piped body\nsecond line")
        XCTAssertEqual(received.level, .info)
    }

    func testInvalidLevelExitsNonZeroAndDropsNothing() throws {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        let status = try runCLI(
            ["notify", "--title", "T", "--summary", "S", "--level", "bogus"],
            inbox: inbox
        )
        XCTAssertNotEqual(status, 0)
        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)
    }

    func testMissingTitleOrSummaryExitsNonZero() throws {
        let inbox = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: inbox) }

        // No title.
        XCTAssertNotEqual(try runCLI(["notify", "--summary", "S"], inbox: inbox), 0)
        // No summary and no stdin (an empty pipe stands in for "nothing piped").
        XCTAssertNotEqual(try runCLI(["notify", "--title", "T"], stdin: "", inbox: inbox), 0)
        XCTAssertEqual(eligibleJSONCount(in: inbox), 0)
    }

    func testHelpIsAvailableForRootAndSubcommand() throws {
        let root = try runCLICapturingStdout(["--help"])
        XCTAssertEqual(root.status, 0)
        XCTAssertTrue(root.stdout.contains("dynamicnotch"))
        XCTAssertTrue(root.stdout.contains("notify"))

        let notify = try runCLICapturingStdout(["notify", "--help"])
        XCTAssertEqual(notify.status, 0)
        XCTAssertTrue(notify.stdout.contains("--title"))
        XCTAssertTrue(notify.stdout.contains("--summary"))
        XCTAssertTrue(notify.stdout.contains("--level"))
    }

    func testInboxDirectoryIsCreatedWhenAbsent() throws {
        let parent = makeTemporaryInboxDirectory()
        defer { try? FileManager.default.removeItem(at: parent) }
        // A path the CLI must `mkdir -p` before it can drop.
        let inbox = parent.appendingPathComponent("does/not/exist/yet", isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: inbox.path))

        let status = try runCLI(["notify", "--title", "T", "--summary", "S"], inbox: inbox)
        XCTAssertEqual(status, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: inbox.path))

        let received = try ingestSingleDrop(from: inbox)
        XCTAssertEqual(received.title, "T")
        XCTAssertEqual(received.summary, "S")
    }
}

private extension CLINotifyIntegrationTests {
    /// The `dynamicnotch` product lands next to the test host app in `BUILT_PRODUCTS_DIR`
    /// (`Bundle.main` is the host app for a hosted unit test). An env override is honoured first
    /// as cheap insurance for unusual layouts.
    func dynamicnotchBinaryURL() throws -> URL {
        if let override = ProcessInfo.processInfo.environment["DYNAMICNOTCH_CLI_BIN"],
           !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        let binary = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("dynamicnotch", isDirectory: false)
        try XCTSkipUnless(
            FileManager.default.isExecutableFile(atPath: binary.path),
            "dynamicnotch binary not found at \(binary.path)"
        )
        return binary
    }

    /// Launches the built CLI with `$DYNAMICNOTCH_INBOX` pointed at `inbox`. When `stdin` is
    /// supplied it is piped in and the write end closed (EOF) so the CLI's stdin read completes.
    @discardableResult
    func runCLI(_ arguments: [String], stdin: String? = nil, inbox: URL) throws -> Int32 {
        let process = Process()
        process.executableURL = try dynamicnotchBinaryURL()
        process.arguments = arguments

        var environment = ProcessInfo.processInfo.environment
        environment["DYNAMICNOTCH_INBOX"] = inbox.path
        process.environment = environment

        let stdinPipe = Pipe()
        process.standardInput = stdinPipe
        // stdout/stderr are captured but not drained — safe because the CLI's output (help,
        // error messages) is far under the 64 KB pipe buffer. A verbose future subcommand that
        // exceeded that before exit could deadlock and would need an async drain here.
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        if let stdin {
            try? stdinPipe.fileHandleForWriting.write(contentsOf: Data(stdin.utf8))
        }
        try? stdinPipe.fileHandleForWriting.close()
        process.waitUntilExit()
        return process.terminationStatus
    }

    /// Runs the built CLI (no inbox needed) and returns its exit status and captured stdout —
    /// used to assert `--help` output.
    func runCLICapturingStdout(_ arguments: [String]) throws -> (status: Int32, stdout: String) {
        let process = Process()
        process.executableURL = try dynamicnotchBinaryURL()
        process.arguments = arguments

        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()
        process.standardInput = FileHandle.nullDevice

        try process.run()
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    /// Runs the real `NotificationInboxMonitor` over `inbox` and returns the single payload it
    /// ingests. Fails the test if nothing arrives within the timeout.
    func ingestSingleDrop(from inbox: URL) throws -> NotificationPayload {
        let monitor = NotificationInboxMonitor(inboxDirectory: inbox, retryDelay: 0)
        let ingested = expectation(description: "monitor ingests the CLI drop")
        let box = PayloadBox()
        monitor.onPayload = { payload in
            box.value = payload
            ingested.fulfill()
        }
        monitor.startMonitoring()
        wait(for: [ingested], timeout: 10.0)
        monitor.stopMonitoring()
        return try XCTUnwrap(box.value)
    }
}

/// Thread-safe holder — `onPayload` fires on the monitor's queue while the test thread reads it.
private final class PayloadBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: NotificationPayload?

    var value: NotificationPayload? {
        get { lock.lock(); defer { lock.unlock() }; return stored }
        set { lock.lock(); defer { lock.unlock() }; stored = newValue }
    }
}
