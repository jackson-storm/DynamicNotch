import Foundation
import NotificationContract

/// The testable heart of `dynamicnotch notify`: given an already-resolved inbox directory
/// and the pieces of a payload, it builds a `NotificationPayload` and drops it atomically.
///
/// It is deliberately free of argument parsing, stdin reading and process I/O — the `main()`
/// glue (parsing + resolving stdin + calling this) stays thin. Because an executable target's
/// symbols aren't importable as a module, this core is exercised *transitively* through the
/// built binary by the seam-2 integration test rather than by an isolated unit test.
enum NotifyCore {
    /// Builds a `NotificationPayload` from the resolved fields and drops it atomically into
    /// `inbox` (created if absent). Returns the URL of the placed `<uuid>.json` file.
    @discardableResult
    static func run(
        title: String,
        summary: String,
        level: NotificationLevel,
        source: String?,
        icon: String?,
        inbox: URL
    ) throws -> URL {
        let payload = NotificationPayload(
            title: title,
            summary: summary,
            level: level,
            source: source,
            icon: icon
        )
        return try AtomicInboxDrop.write(payload, to: inbox)
    }
}
