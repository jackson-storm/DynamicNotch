import Foundation

@MainActor
protocol ClockTimerControlling: AnyObject {
    func togglePauseResume() async -> Bool
    func stopTimer() async -> Bool
}
