//
//  TimerSource.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/30/26.
//

import SwiftUI

enum TimerSource {
    case system(TimerViewModel)
    case local(LocalTimerViewModel)

    var isPaused: Bool {
        switch self {
        case .system(let vm):
            return vm.snapshot?.isPaused ?? false
        case .local(let vm):
            return vm.state == .paused
        }
    }

    var isRunningOrPaused: Bool {
        switch self {
        case .system(let vm):
            return vm.hasActiveTimer
        case .local(let vm):
            return vm.state == .running || vm.state == .paused
        }
    }

    func remainingTime(at date: Date) -> TimeInterval {
        switch self {
        case .system(let vm):
            return vm.snapshot?.remainingTime(at: date) ?? 0
        case .local(let vm):
            return vm.remainingTime(at: date)
        }
    }

    func progress(at date: Date) -> Double {
        switch self {
        case .system(let vm):
            return vm.snapshot?.progress(at: date) ?? 0
        case .local(let vm):
            guard vm.totalTime > 0 else { return 0 }
            let remaining = vm.remainingTime(at: date)
            return min(max(1.0 - (remaining / vm.totalTime), 0), 1)
        }
    }

    var countdownFlipOffset: TimeInterval {
        switch self {
        case .system(let vm):
            // Clock rounds its countdown to the nearest second, at redraws that land
            // `displayDelay` after each half-second crossing.
            guard let snapshot = vm.snapshot, !snapshot.isPaused else { return 0.5 }
            return 0.5 - snapshot.displayDelay
        case .local:
            return 0
        }
    }

    var countdownEndDate: Date? {
        switch self {
        case .system(let vm):
            return vm.snapshot?.endDate
        case .local(let vm):
            return vm.endDate
        }
    }

    func displayedSeconds(at date: Date) -> Int {
        TimerCountdownSchedule.displayedSeconds(remaining: remainingTime(at: date), flipOffset: countdownFlipOffset)
    }

    func formattedTime(at date: Date) -> String {
        let seconds = TimeInterval(displayedSeconds(at: date))

        switch self {
        case .system(let vm):
            return vm.formatTime(seconds)
        case .local(let vm):
            return vm.formatTime(seconds)
        }
    }

    @MainActor
    func togglePauseResume() async {
        switch self {
        case .system(let vm):
            _ = await vm.togglePauseResume()
        case .local(let vm):
            if vm.state == .paused {
                vm.resume()
            } else {
                vm.pause()
            }
        }
    }

    @MainActor
    func stopTimer() async {
        switch self {
        case .system(let vm):
            _ = await vm.stopTimer()
        case .local(let vm):
            vm.stop()
        }
    }
}
