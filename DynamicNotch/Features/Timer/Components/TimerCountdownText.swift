//
//  TimerCountdownText.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/17/26.
//

import SwiftUI

struct TimerCountdownText: View {
    let source: TimerSource

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.25, paused: source.isPaused)) { context in
            let formatted = source.formattedTime(at: context.date)
            Text(formatted)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.orange)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.28, extraBounce: 0.12), value: formatted)
        }
    }
}
