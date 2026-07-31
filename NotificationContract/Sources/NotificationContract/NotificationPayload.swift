import Foundation

/// The script-authored contract dropped as JSON into the inbox. `title` and `summary`
/// are required; the rest are optional. A missing or blank `title`/`summary` fails
/// decoding — the drop is rejected at parse time rather than producing a blank row.
///
/// `Codable`: the custom `init(from:)` keeps the decode-time validation (and the tolerant
/// unknown-`level` → `.info` behaviour), while `encode(to:)` is synthesized. The
/// `CodingKeys` enum lives in the type body (not a `private` decode-only extension) so the
/// synthesized `Encodable` can see it.
public struct NotificationPayload: Equatable, Codable {
    public let title: String
    public let summary: String
    public let level: NotificationLevel
    public let source: String?
    public let icon: String?

    /// Direct construction (used by the CLI core and by tests). The synthesized memberwise
    /// init is `internal`, so an explicit `public` one is required for cross-module callers.
    public init(
        title: String,
        summary: String,
        level: NotificationLevel = .info,
        source: String? = nil,
        icon: String? = nil
    ) {
        self.title = title
        self.summary = summary
        self.level = level
        self.source = source
        self.icon = icon
    }

    enum CodingKeys: String, CodingKey {
        case title, summary, level, source, icon
    }

    public init(from decoder: Decoder) throws {
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
