#if DEBUG
internal import AppKit
import Foundation
import NotificationContract

/// Debug-only helper that drives the notifications feature through its *real* pipeline by
/// writing files into the app's watched inbox. The running app owns the live
/// `NotificationInboxMonitor` (see `AppContainer`), so a drop here flows all the way
/// through watch → parse → view model → carousel page → persistence.
///
/// It deliberately does **not** talk to a `NotificationCenterViewModel`: the settings
/// Debug factory wires an `InactiveNotificationInboxMonitor` and its own throwaway view
/// model, so calling into that would update nothing on screen. The filesystem is the one
/// seam shared with the real app — which also makes these actions exercise the genuine
/// ingestion path rather than a shortcut.
struct NotificationInboxDebugTool {
    private let inboxDirectory: URL
    private let fileManager: FileManager

    init(
        inboxDirectory: URL,
        fileManager: FileManager = .default
    ) {
        self.inboxDirectory = inboxDirectory
        self.fileManager = fileManager
    }

    /// Atomically drops a valid notification of `level` through the shared `AtomicInboxDrop`
    /// mechanism, so the watcher never reads a half-written file. Expect a new row of the
    /// matching severity on the carousel page.
    func injectSample(level: NotificationLevel) {
        let payload: [String: Any] = [
            "title": Self.sampleTitle(for: level),
            "summary": Self.sampleSummary(for: level),
            "level": level.rawValue,
            "source": "debug-tab"
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        write(data)
    }

    /// Drops an invalid `.json` so it exercises the retry-then-quarantine path: the monitor
    /// fails to parse it and moves it to `inbox/rejected/` instead of adding a row.
    func injectMalformed() {
        write(Data("{ not valid json ".utf8))
    }

    /// Reveals the inbox folder in Finder (including `rejected/`) for manual inspection.
    func revealInboxInFinder() {
        ensureInboxExists()
        NSWorkspace.shared.activateFileViewerSelecting([inboxDirectory])
    }

    /// Empties the inbox on disk — pending drops *and* `rejected/`. The watched folder
    /// itself is kept so the live monitor's file descriptor stays valid. This does not
    /// touch the in-app persisted list (use the carousel page's "Clear" for that).
    func clearInbox() {
        guard let entries = try? fileManager.contentsOfDirectory(
            at: inboxDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        for url in entries {
            try? fileManager.removeItem(at: url)
        }
    }
}

private extension NotificationInboxDebugTool {
    func ensureInboxExists() {
        try? fileManager.createDirectory(at: inboxDirectory, withIntermediateDirectories: true)
    }

    /// Writes `data` under a fresh `<uuid>.json` name — the only shape the monitor treats as
    /// eligible. The atomic write itself is `AtomicInboxDrop`'s (temp `.`-prefixed + rename,
    /// creates the inbox if absent), shared with the CLI and the app so no second
    /// implementation can drift. `injectSample` feeds valid JSON, `injectMalformed` invalid —
    /// both share this one drop path.
    func write(_ data: Data) {
        let url = inboxDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try? AtomicInboxDrop.writeAtomically(data, to: url)
    }

    static func sampleTitle(for level: NotificationLevel) -> String {
        switch level {
        case .info: "Info notification"
        case .success: "Success notification"
        case .warning: "Warning notification"
        case .error: "Error notification"
        }
    }

    static func sampleSummary(for level: NotificationLevel) -> String {
        "A sample \(level.rawValue)-level notification dropped from the Debug tab."
    }
}
#endif
