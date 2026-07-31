import ArgumentParser
import Foundation
import NotificationContract

/// `dynamicnotch` — a thin CLI over the inbox file-drop contract. It builds a valid
/// `NotificationPayload` and drops it atomically, so scripts never hand-roll JSON escaping
/// or the temp-file `rename` dance. See `docs/cli-notify-feature-spec.md`.
@main
struct DynamicNotchCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dynamicnotch",
        abstract: "Push a notification into DynamicNotch from any process.",
        subcommands: [Notify.self]
    )
}

/// Strict `--level` parsing: an unknown value yields `nil`, which argument-parser turns into
/// an immediate usage error (exit ≠ 0) — never a silent downgrade to `.info`.
extension NotificationLevel: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument)
    }

    public static var allValueStrings: [String] { allCases.map(\.rawValue) }
}

struct Notify: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Drop a notification into the DynamicNotch inbox."
    )

    @Option(name: .long, help: "Short title.")
    var title: String

    @Option(name: .long, help: "Body text. Required via this flag OR piped on stdin.")
    var summary: String?

    @Option(name: .long, help: "Severity: info | success | warning | error.")
    var level: NotificationLevel = .info

    @Option(name: .long, help: "Coalescing key / subtitle.")
    var source: String?

    @Option(name: .long, help: "SF Symbol name (app-side fallback if invalid).")
    var icon: String?

    func run() throws {
        try NotifyCore.run(
            title: title,
            summary: try resolveSummary(),
            level: level,
            source: source,
            icon: icon,
            inbox: NotificationInbox.resolvedURL
        )
    }

    /// `--summary` wins; otherwise the whole of stdin is the summary. stdin is only consumed
    /// when it is piped/redirected — a TTY is treated as "no summary" so an interactive
    /// invocation errors immediately instead of blocking on `readDataToEndOfFile()`.
    private func resolveSummary() throws -> String {
        if let summary { return summary }

        if isatty(FileHandle.standardInput.fileDescriptor) == 0 {
            let data = FileHandle.standardInput.readDataToEndOfFile()
            let piped = String(decoding: data, as: UTF8.self)
            if !piped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return piped
            }
        }

        throw ValidationError("Provide --summary or pipe the body on stdin.")
    }
}
