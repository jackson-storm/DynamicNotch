//
//  TimerCountdownText.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/17/26.
//

import SwiftUI

struct TimerCountdownText: View {
    let snapshot: ClockTimerSnapshot

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.25, paused: snapshot.isPaused)) { context in
            Text(Self.formattedTime(snapshot.remainingTime(at: context.date)))
                .font(.system(size: 14, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.28, extraBounce: 0.12), value: Self.formattedTime(snapshot.remainingTime(at: context.date)))
        }
    }

    private static func formattedTime(_ remainingTime: TimeInterval) -> String {
        let displaySeconds = max(0, Int(ceil(remainingTime)))

        if displaySeconds < 60 {
            return secondsFormatter.string(from: TimeInterval(displaySeconds)) ?? "0:00"
        }

        return abbreviatedEnglishTime(displaySeconds)
    }

    private static func abbreviatedEnglishTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0, minutes > 0 {
            return "\(hours) h \(minutes) min"
        }

        if hours > 0 {
            return "\(hours) h"
        }

        return "\(minutes) min"
    }

    private static let secondsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        return formatter
    }()
}
