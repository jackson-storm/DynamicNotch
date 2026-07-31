import Foundation

/// Severity of a notification: `info < success < warning < error`. This is the *core*
/// of the level — the wire-facing rawValue, its `Codable` derivation and the severity
/// ordering `highestUnreadLevel` relies on. The presentation bits (`color`,
/// `defaultIconName`) stay app-side as an extension on this imported enum, so the module
/// keeps zero UI dependencies.
public enum NotificationLevel: String, Codable, CaseIterable, Comparable {
    case info
    case success
    case warning
    case error

    private var severity: Int {
        switch self {
        case .info: 0
        case .success: 1
        case .warning: 2
        case .error: 3
        }
    }

    public static func < (lhs: NotificationLevel, rhs: NotificationLevel) -> Bool {
        lhs.severity < rhs.severity
    }
}
