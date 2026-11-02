import Foundation

nonisolated enum TimerCountdownSchedule {
    /// Returns the latest date at or before `now` that is a whole number of seconds before
    /// `endDate`. A one-second periodic schedule from this date fires exactly when the remaining
    /// time crosses a second. A past `endDate` remains unchanged.
    static func start(endDate: Date, now: Date) -> Date {
        let remaining = endDate.timeIntervalSince(now)
        guard remaining > 0 else { return endDate }

        let wholeSeconds = remaining.rounded()
        let offset = abs(remaining - wholeSeconds) < 0.000_001 ? wholeSeconds : remaining.rounded(.up)

        let start = endDate.addingTimeInterval(-offset)
        // This absorbs floating-point error, which is far below a display frame.
        return min(start, now)
    }
}
