//
//  TimerSource.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/30/26.
//

import SwiftUI

enum TimerSource {
    case system(TimerViewModel)

    var isPaused: Bool {
        switch self {
        case .system(let vm):
            return vm.snapshot?.isPaused ?? false
        }
    }

    var isRunningOrPaused: Bool {
        switch self {
        case .system(let vm):
            return vm.hasActiveTimer
        }
    }

    func remainingTime(at date: Date) -> TimeInterval {
        switch self {
        case .system(let vm):
            return vm.snapshot?.remainingTime(at: date) ?? 0
        }
    }

    func progress(at date: Date) -> Double {
        switch self {
        case .system(let vm):
            return vm.snapshot?.progress(at: date) ?? 0
        }
    }

    func formattedTime(at date: Date) -> String {
        switch self {
        case .system(let vm):
            return vm.formattedTime
        }
    }

    @MainActor
    func togglePauseResume() async {
        switch self {
        case .system(let vm):
            _ = await vm.togglePauseResume()
        }
    }

    @MainActor
    func stopTimer() async {
        switch self {
        case .system(let vm):
            _ = await vm.stopTimer()
        }
    }
}
