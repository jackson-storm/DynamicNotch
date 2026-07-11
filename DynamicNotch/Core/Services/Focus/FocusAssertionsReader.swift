import Foundation

/// Authoritative source of the currently active Focus mode on recent macOS.
///
/// The distributed `_NSDoNotDisturb*` notifications and the `duetexpertd` unified
/// log both became unreliable on macOS 26 — the enable notification may fire
/// without a usable mode identifier, the disable notification often doesn't fire
/// at all, and the log stream can stay silent. As a result the notch couldn't
/// tell *which* mode was on (wrong icon/colour) and missed Focus being turned off.
///
/// `~/Library/DoNotDisturb/DB/Assertions.json` is the file macOS itself writes
/// when a Focus assertion is added or removed. Reading it tells us both whether a
/// Focus is active and its exact mode identifier. The file is protected by Full
/// Disk Access, so this only works once the user grants it — hence `.unreadable`
/// is distinct from `.off`, letting callers leave the legacy behaviour untouched
/// when access isn't available.
enum FocusAssertionState: Equatable {
    case unreadable
    case off
    case on(identifier: String)
}

final class FocusAssertionsReader {
    static let shared = FocusAssertionsReader()

    private let path = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Library/DoNotDisturb/DB/Assertions.json")

    private init() {}

    var fileURL: URL { path }

    private struct AssertionsRoot: Decodable {
        let data: [Entry]
    }

    private struct Entry: Decodable {
        let storeAssertionRecords: [Record]?
    }

    private struct Record: Decodable {
        let assertionDetails: Details?
    }

    private struct Details: Decodable {
        let assertionDetailsModeIdentifier: String?
    }

    func readState() -> FocusAssertionState {
        guard let data = try? Data(contentsOf: path) else {
            // No Full Disk Access (or the file doesn't exist yet).
            return .unreadable
        }

        guard let root = try? JSONDecoder().decode(AssertionsRoot.self, from: data) else {
            // Readable but empty/short — macOS truncates this file to a small stub
            // when no Focus is active, so an unparseable/emptyish payload means off.
            return .off
        }

        for entry in root.data {
            for record in entry.storeAssertionRecords ?? [] {
                if let identifier = record.assertionDetails?.assertionDetailsModeIdentifier,
                   !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return .on(identifier: identifier)
                }
            }
        }

        return .off
    }
}
