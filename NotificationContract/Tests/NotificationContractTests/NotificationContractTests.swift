import Foundation
import Testing
@testable import NotificationContract

// Seam 1 — pure logic of the shared contract, no Xcode, no signing.

@Suite("NotificationPayload Codable")
struct NotificationPayloadCodableTests {
    @Test("round-trips a fully populated payload")
    func roundTripFull() throws {
        let payload = NotificationPayload(
            title: "Backup nightly",
            summary: "42 files, 1.2 GB\nOK",
            level: .success,
            source: "backup.sh",
            icon: "externaldrive.badge.checkmark"
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(NotificationPayload.self, from: data)

        #expect(decoded == payload)
    }

    @Test("round-trips a payload with nil source and icon, restoring nil")
    func roundTripNilOptionals() throws {
        let payload = NotificationPayload(title: "Just a title", summary: "and a body")

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(NotificationPayload.self, from: data)

        #expect(decoded == payload)
        #expect(decoded.source == nil)
        #expect(decoded.icon == nil)
    }

    @Test("encodes the wire keys title/summary/level")
    func encodesWireKeys() throws {
        let payload = NotificationPayload(title: "T", summary: "S", level: .warning)

        let data = try JSONEncoder().encode(payload)
        let object = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(object["title"] as? String == "T")
        #expect(object["summary"] as? String == "S")
        #expect(object["level"] as? String == "warning")
        // nil optionals are omitted by the synthesized encoder.
        #expect(object["source"] == nil)
        #expect(object["icon"] == nil)
    }

    @Test("unknown level decodes to .info instead of failing")
    func unknownLevelTolerated() throws {
        let json = Data(#"{"title":"T","summary":"S","level":"bogus"}"#.utf8)

        let decoded = try JSONDecoder().decode(NotificationPayload.self, from: json)

        #expect(decoded.level == .info)
    }

    @Test("absent level decodes to .info")
    func absentLevelDefaultsToInfo() throws {
        let json = Data(#"{"title":"T","summary":"S"}"#.utf8)

        let decoded = try JSONDecoder().decode(NotificationPayload.self, from: json)

        #expect(decoded.level == .info)
    }

    @Test("blank title fails decoding")
    func blankTitleThrows() {
        let json = Data(#"{"title":"   ","summary":"S"}"#.utf8)

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(NotificationPayload.self, from: json)
        }
    }

    @Test("blank summary fails decoding")
    func blankSummaryThrows() {
        let json = Data(#"{"title":"T","summary":"\n"}"#.utf8)

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(NotificationPayload.self, from: json)
        }
    }
}

@Suite("NotificationLevel ordering")
struct NotificationLevelTests {
    @Test("is ordered info < success < warning < error")
    func severityOrdering() {
        #expect(NotificationLevel.info < .success)
        #expect(NotificationLevel.success < .warning)
        #expect(NotificationLevel.warning < .error)
        #expect(NotificationLevel.allCases.max() == .error)
    }
}

@Suite("NotificationInbox path derivation")
struct NotificationInboxTests {
    @Test("defaultURL points at Application Support/DynamicNotch/inbox")
    func defaultPath() {
        let url = NotificationInbox.defaultURL
        #expect(url.lastPathComponent == "inbox")
        #expect(url.deletingLastPathComponent().lastPathComponent == "DynamicNotch")
    }

    @Test("resolvedURL honors $DYNAMICNOTCH_INBOX when set")
    func resolvedHonorsEnv() throws {
        let override = "/tmp/dynamicnotch-test-inbox-\(UUID().uuidString)"
        setenv("DYNAMICNOTCH_INBOX", override, 1)
        defer { unsetenv("DYNAMICNOTCH_INBOX") }

        #expect(NotificationInbox.resolvedURL.path == override)
    }

    @Test("resolvedURL falls back to defaultURL when env is unset")
    func resolvedFallsBack() {
        unsetenv("DYNAMICNOTCH_INBOX")
        #expect(NotificationInbox.resolvedURL == NotificationInbox.defaultURL)
    }
}

@Suite("AtomicInboxDrop")
struct AtomicInboxDropTests {
    private func makeTempDir() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("writes a <uuid>.json final file that re-decodes to the payload")
    func dropsDecodableFile() throws {
        let inbox = makeTempDir()
        let payload = NotificationPayload(title: "Hello", summary: "World", level: .error)

        let finalURL = try AtomicInboxDrop.write(payload, to: inbox)

        #expect(finalURL.pathExtension == "json")
        #expect(!finalURL.lastPathComponent.hasPrefix("."))
        let decoded = try JSONDecoder().decode(
            NotificationPayload.self,
            from: Data(contentsOf: finalURL)
        )
        #expect(decoded == payload)
    }

    @Test("creates the inbox directory when absent")
    func createsInboxWhenAbsent() throws {
        let inbox = makeTempDir().appendingPathComponent("nested/inbox", isDirectory: true)
        #expect(!FileManager.default.fileExists(atPath: inbox.path))

        let finalURL = try AtomicInboxDrop.write(
            NotificationPayload(title: "T", summary: "S"),
            to: inbox
        )

        #expect(FileManager.default.fileExists(atPath: finalURL.path))
    }

    @Test("uses a unique final name per invocation")
    func uniqueNamePerCall() throws {
        let inbox = makeTempDir()
        let payload = NotificationPayload(title: "T", summary: "S")

        let a = try AtomicInboxDrop.write(payload, to: inbox)
        let b = try AtomicInboxDrop.write(payload, to: inbox)

        #expect(a.lastPathComponent != b.lastPathComponent)
        let count = try FileManager.default
            .contentsOfDirectory(atPath: inbox.path)
            .filter { $0.hasSuffix(".json") }
            .count
        #expect(count == 2)
    }

    @Test("leaves no leftover dotfile temp behind")
    func leavesNoTemp() throws {
        let inbox = makeTempDir()

        try AtomicInboxDrop.write(NotificationPayload(title: "T", summary: "S"), to: inbox)

        let leftovers = try FileManager.default
            .contentsOfDirectory(atPath: inbox.path)
            .filter { $0.hasPrefix(".") }
        #expect(leftovers.isEmpty)
    }
}
