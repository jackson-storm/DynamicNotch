import Foundation
import NotificationContract

// Shared filesystem helpers for inbox-monitor tests: make a throwaway inbox, drop files
// atomically, and count what is left behind. The atomic write itself delegates to
// `AtomicInboxDrop` — the same mechanism the CLI and app use — so there is no second
// implementation to drift. These helpers still choose the *final* name (including dotfiles
// and non-`.json`) so tests can feed the monitor adversarial drops the production path
// would never produce.

func makeTemporaryInboxDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

func atomicDrop(
    _ payload: [String: Any],
    named name: String = "\(UUID().uuidString).json",
    in directory: URL
) {
    let data = try! JSONSerialization.data(withJSONObject: payload)
    try! AtomicInboxDrop.writeAtomically(data, to: directory.appendingPathComponent(name))
}

func atomicDropRaw(_ contents: String, named name: String, in directory: URL) {
    try! AtomicInboxDrop.writeAtomically(
        Data(contents.utf8),
        to: directory.appendingPathComponent(name)
    )
}

/// Eligible (non-dotfile) `.json` files still awaiting ingestion — the same eligibility rule
/// the monitor applies, in one place so drop tests and count checks can't drift.
func eligibleJSONFiles(in directory: URL) -> [URL] {
    let urls = (try? FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil
    )) ?? []
    return urls.filter { $0.pathExtension == "json" && !$0.lastPathComponent.hasPrefix(".") }
}

/// Count of eligible (non-dotfile) `.json` files still awaiting ingestion.
func eligibleJSONCount(in directory: URL) -> Int {
    eligibleJSONFiles(in: directory).count
}

/// Files quarantined in `inbox/rejected/`.
func rejectedFileCount(in inbox: URL) -> Int {
    let rejected = inbox.appendingPathComponent("rejected", isDirectory: true)
    let urls = (try? FileManager.default.contentsOfDirectory(
        at: rejected,
        includingPropertiesForKeys: nil
    )) ?? []
    return urls.count
}
