import Foundation

/// Single source of truth for *where* the inbox lives. Both the app (draining) and the
/// CLI (dropping) resolve the directory here so they can never disagree.
public enum NotificationInbox {
    /// `~/Library/Application Support/DynamicNotch/inbox` — the canonical location.
    public static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DynamicNotch", isDirectory: true)
            .appendingPathComponent("inbox", isDirectory: true)
    }

    /// `$DYNAMICNOTCH_INBOX` when set to a non-empty path (tests + power-users), otherwise
    /// `defaultURL`.
    public static var resolvedURL: URL {
        if let override = ProcessInfo.processInfo.environment["DYNAMICNOTCH_INBOX"],
           !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return defaultURL
    }
}
