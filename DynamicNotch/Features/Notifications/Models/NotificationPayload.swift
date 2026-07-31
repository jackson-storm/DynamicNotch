import Foundation

/// The script-authored contract dropped as JSON into the inbox. `title` and `summary`
/// are required; the rest are optional. A missing or blank `title`/`summary` fails
/// decoding — the file is rejected at parse time rather than producing a blank row.
struct NotificationPayload: Equatable {
    let title: String
    let summary: String
    let level: NotificationLevel
    let source: String?
    let icon: String?
}

extension NotificationPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case title, summary, level, source, icon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let title = try container.decode(String.self, forKey: .title)
        let summary = try container.decode(String.self, forKey: .summary)

        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .title,
                in: container,
                debugDescription: "title must not be blank"
            )
        }
        guard !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .summary,
                in: container,
                debugDescription: "summary must not be blank"
            )
        }

        self.title = title
        self.summary = summary
        // Unknown or absent level is tolerated and treated as `.info` — a level typo
        // must never cost the user the whole notification.
        self.level = (try container.decodeIfPresent(String.self, forKey: .level))
            .flatMap(NotificationLevel.init(rawValue:)) ?? .info
        self.source = try container.decodeIfPresent(String.self, forKey: .source)
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
    }
}
