internal import AppKit
import NotificationContract
import SwiftUI

// `NotificationLevel` and `NotificationPayload` are the wire contract, now owned by the
// `NotificationContract` module (shared with the `dynamicnotch` CLI). Only the
// *presentation* of a level — its tint and default SF Symbol — stays app-side, as an
// extension on the imported enum, so the module keeps zero UI dependencies.
extension NotificationLevel {
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

    /// Replaces all script-authored fields with those from a newer payload and re-marks the
    /// item unread. The `id` is preserved so detail views keyed by id survive coalescence.
    /// `unreadCount` is computed from `read` — flipping to `false` implicitly increments it
    /// if the item was previously read; no separate badge counter exists.
    mutating func apply(_ payload: NotificationPayload, receivedAt: Date) {
        title = payload.title
        summary = payload.summary
        level = payload.level
        icon = payload.icon
        self.receivedAt = receivedAt
        read = false
    }

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
