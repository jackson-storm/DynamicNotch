import Foundation

/// The one and only atomic-drop mechanism, shared by the CLI, the app and the tests so no
/// two writers can diverge. Fixes the two defects of the historical `mv drop.json`
/// one-liner:
///
/// 1. **Unique final name.** Each drop lands as `<uuid>.json`, so a burst never collides
///    (a fixed name would let the second `mv` clobber the first before ingestion).
/// 2. **Same-directory temp.** The temp file is `.`-prefixed (ignored by the monitor) and
///    written *inside the inbox*, then `rename`d within that same directory. Keeping the
///    temp beside the final file means the move is always within one volume — a plain
///    atomic `rename` — never a cross-volume copy from `NSTemporaryDirectory()`.
public enum AtomicInboxDrop {
    /// Encodes `payload` and drops it atomically into `inboxDirectory` as `<uuid>.json`,
    /// creating the directory if absent. Returns the URL of the placed file.
    @discardableResult
    public static func write(
        _ payload: NotificationPayload,
        to inboxDirectory: URL
    ) throws -> URL {
        let data = try JSONEncoder().encode(payload)
        let finalURL = inboxDirectory
            .appendingPathComponent("\(UUID().uuidString).json", isDirectory: false)
        try writeAtomically(data, to: finalURL)
        return finalURL
    }

    /// Places `data` at `finalURL` atomically: writes a `.`-prefixed temp in the *same*
    /// directory, then renames it onto `finalURL`. Creates the parent directory if absent.
    /// The caller chooses the final name — production/CLI pass `<uuid>.json`; tests may pass
    /// arbitrary (even dotfile or non-`.json`) names to exercise the monitor.
    public static func writeAtomically(_ data: Data, to finalURL: URL) throws {
        let directory = finalURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let tempURL = directory.appendingPathComponent(
            ".\(UUID().uuidString).tmp",
            isDirectory: false
        )
        try data.write(to: tempURL, options: .atomic)
        do {
            try FileManager.default.moveIntoPlace(tempURL, onto: finalURL)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
    }
}

private extension FileManager {
    /// Moves `tempURL` onto `finalURL` inside the inbox. Production final names are unique
    /// UUIDs, so the destination never pre-exists and this is a single atomic `rename`.
    /// The `removeItem` guard only fires for the tests' fixed-name drops, where the tiny
    /// non-atomic window between remove and move is harmless (tests drop then poll). Named to
    /// avoid colliding with Foundation's `replaceItem(at:withItemAt:...)`, which would stage
    /// its own backup temp *outside* the inbox.
    func moveIntoPlace(_ tempURL: URL, onto finalURL: URL) throws {
        if fileExists(atPath: finalURL.path) {
            try removeItem(at: finalURL)
        }
        try moveItem(at: tempURL, to: finalURL)
    }
}
