import Foundation

// Shared filesystem helpers for inbox-monitor tests: make a throwaway inbox, drop files
// atomically (temp + rename, mirroring the reference script so the watcher never observes a
// half-written file), and count what is left behind.

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
    try! data.write(to: directory.appendingPathComponent(name), options: .atomic)
}

func atomicDropRaw(_ contents: String, named name: String, in directory: URL) {
    try! Data(contents.utf8).write(to: directory.appendingPathComponent(name), options: .atomic)
}

/// Eligible (non-dotfile) `.json` files still awaiting ingestion.
func eligibleJSONCount(in directory: URL) -> Int {
    let urls = (try? FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil
    )) ?? []
    return urls.filter { $0.pathExtension == "json" && !$0.lastPathComponent.hasPrefix(".") }.count
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
