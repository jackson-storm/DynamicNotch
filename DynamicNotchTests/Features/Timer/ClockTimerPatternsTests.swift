import XCTest
@testable import DynamicNotch

final class ClockTimerPatternsTests: XCTestCase {
    private let cases: [(NSRegularExpression?, String, [String])] = [
        (ClockTimerPatterns.startedTimer, "started timer:\\s*([A-Fa-f0-9\\-]+)", ["started timer: AB12-cd34", "started timer:", "noise"]),
        (ClockTimerPatterns.nextTimerChanged, "next timer changed:\\s*([^\n]+)", ["next timer changed: <MTTimer 1>\nnext", "next timer changed:"]),
        (ClockTimerPatterns.willFire, "Timer will fire\\s+([0-9.]+)\\s+minutes?", ["Timer will fire 4.5 minutes", "Timer will fire 1 minute", "Timer will fire soon"]),
        (ClockTimerPatterns.remainingTime, "remainingTime:\\s*([-0-9.]+)", ["remainingTime: -12.5", "remainingTime:"]),
        (ClockTimerPatterns.loggedTimer, "<MT(?:Mutable)?Timer:[^>]+>", ["<MTTimer: a> <MTMutableTimer: b>", "<MTTimer:>"]),
        (ClockTimerPatterns.timerID, "TimerID:\\s*([A-Fa-f0-9\\-]+)", ["TimerID: 0F-aa", "TimerID: zz"]),
        (ClockTimerPatterns.state, "state:([A-Za-z]+)", ["state:Running, x", "state: paused"]),
        (ClockTimerPatterns.title, "Title:\\s*([^,]+)", ["Title: Tea, duration:300", "Title:,"]),
        (ClockTimerPatterns.duration, "duration:([0-9]+(?:\\.[0-9]+)?)", ["duration:300.25", "duration:12", "duration:x"]),
        (ClockTimerPatterns.unitCountdown, "([0-9]+)([hms])", ["1h 2m 3s", "10m", "Timer"])
    ]

    func testPrecompiledPatternsMatchFreshlyCompiledOnes() throws {
        for (precompiled, pattern, samples) in cases {
            let precompiled = try XCTUnwrap(precompiled, pattern)
            let fresh = try NSRegularExpression(pattern: pattern)
            XCTAssertEqual(precompiled.pattern, fresh.pattern)
            XCTAssertEqual(precompiled.options, fresh.options)

            for sample in samples {
                let range = NSRange(sample.startIndex..<sample.endIndex, in: sample)
                XCTAssertEqual(
                    precompiled.matches(in: sample, range: range).map { allRanges(of: $0) },
                    fresh.matches(in: sample, range: range).map { allRanges(of: $0) },
                    "\(pattern) on \(sample)"
                )
            }
        }
    }

    private func allRanges(of match: NSTextCheckingResult) -> [NSRange] {
        (0..<match.numberOfRanges).map { match.range(at: $0) }
    }
}
