//
//  TimerCountdownText.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/17/26.
//

import SwiftUI

struct TimerCountdownText: View {
    @ObservedObject var timerViewModel: TimerViewModel
    let snapshot: ClockTimerSnapshot

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.25, paused: snapshot.isPaused)) { context in
            Text(timerViewModel.formatTime(snapshot.remainingTime(at: context.date)))
                .font(.system(size: 14, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.28, extraBounce: 0.12), value: timerViewModel.formatTime(snapshot.remainingTime(at: context.date)))
        }
    }
}
