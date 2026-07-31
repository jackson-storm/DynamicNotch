internal import AppKit
import SwiftUI

/// Severity of a notification. Drives the tint and the default SF Symbol when the
/// script does not provide its own `icon`. Ordering (info < success < warning < error)
/// is what `highestUnreadLevel` relies on.
enum NotificationLevel: String, Codable, CaseIterable, Comparable {
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

    static func < (lhs: NotificationLevel, rhs: NotificationLevel) -> Bool {
        lhs.severity < rhs.severity
    }

    var color: Color {
        switch self {
        case .info: .white
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }

    /// Fallback SF Symbol used when the payload does not carry a valid custom `icon`.
    var defaultIconName: String {
        switch self {
        case .info: "bell.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }
}

/// A notification once ingested by the app. The script-provided fields come from
/// `NotificationPayload`; `id`, `receivedAt` and `read` are stamped by the app.
struct NotificationItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var summary: String
    var level: NotificationLevel
    var source: String?
    var icon: String?
    var receivedAt: Date
    var read: Bool

    /// The resolved SF Symbol name for the detail view. Returns the custom `icon` when it
    /// names a valid system symbol; falls back to the level's default otherwise.
    var effectiveIconName: String {
        guard let icon, !icon.isEmpty,
              NSImage(systemSymbolName: icon, accessibilityDescription: nil) != nil else {
            return level.defaultIconName
        }
        return icon
    }
}
