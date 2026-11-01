import Foundation

/// Page selection survives brief closes, using monotonic time rather than the wall clock.
nonisolated struct HomePageSessionMemory {
    private var closedAt: TimeInterval?

    mutating func didClose(at uptime: TimeInterval) {
        closedAt = uptime
    }

    mutating func pageForExpansion<Page>(current: Page, first: Page, at uptime: TimeInterval) -> Page {
        defer { closedAt = nil }
        guard let closedAt, uptime - closedAt >= 5 else { return current }
        return first
    }
}
