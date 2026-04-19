import Foundation

@MainActor
final class InactiveClockTimerController: ClockTimerControlling {
    func togglePauseResume() async -> Bool { false }
    func stopTimer() async -> Bool { false }
}
