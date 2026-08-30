import Foundation

enum ClipboardPayload: Equatable {
    case text(String)
    case files([URL])
    case image(Data)

    var kind: ClipboardItemKind {
        switch self {
        case .text(let text):
            return text.detectedWebURL == nil ? .text : .link
        case .files:
            return .files
        case .image:
            return .image
        }
    }

    var estimatedByteCount: Int {
        switch self {
        case .text(let text):
            return text.utf8.count
        case .files(let urls):
            return urls.reduce(0) { $0 + $1.path.utf8.count }
        case .image(let data):
            return data.count
        }
    }

    var preview: String {
        switch self {
        case .text(let text):
            // Keep previews cheap and useful even when the copied text is near
            // the storage limit. This string is also used by accessibility.
            let previewSource = String(text.prefix(2_048))
            let normalized = previewSource
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\t", with: " ")
                .split(whereSeparator: \Character.isWhitespace)
                .joined(separator: " ")
            guard !normalized.isEmpty else { return "Empty text" }
            let truncated = String(normalized.prefix(160))
            return normalized.count > 160 ? "\(truncated)…" : truncated
        case .files(let urls):
            guard let first = urls.first else { return "No files" }
            if urls.count == 1 {
                return first.lastPathComponent
            }
            return "\(first.lastPathComponent) +\(urls.count - 1) more"
        case .image:
            return "Image"
        }
    }
}

enum ClipboardItemKind: String {
    case text
    case link
    case files
    case image

    var title: String {
        switch self {
        case .text: return "Text"
        case .link: return "Link"
        case .files: return "Files"
        case .image: return "Image"
        }
    }

    var systemImage: String {
        switch self {
        case .text: return "text.alignleft"
        case .link: return "link"
        case .files: return "doc.on.doc"
        case .image: return "photo"
        }
    }
}

struct ClipboardSnapshot: Equatable {
    let payload: ClipboardPayload
    let sourceApplicationName: String?
    let capturedAt: Date
}

struct ClipboardHistoryItem: Identifiable, Equatable {
    let id: UUID
    let payload: ClipboardPayload
    let sourceApplicationName: String?
    let capturedAt: Date

    init(
        id: UUID = UUID(),
        payload: ClipboardPayload,
        sourceApplicationName: String?,
        capturedAt: Date
    ) {
        self.id = id
        self.payload = payload
        self.sourceApplicationName = sourceApplicationName
        self.capturedAt = capturedAt
    }
}

enum ClipboardEvent {
    case captured(ClipboardHistoryItem)
}

struct ClipboardRestoreFailure: Equatable {
    let itemID: UUID
    let message: String
}

private extension String {
    var detectedWebURL: URL? {
        guard let url = URL(string: trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }
}
