//
//  TimerCountdownText.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/17/26.
//

import SwiftUI

struct TimerCountdownText: View {
    let source: TimerSource
    private let endDate: Date?
    private let isPaused: Bool
    private let flipOffset: TimeInterval
    
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen

    init(source: TimerSource) {
        self.source = source
        self.endDate = source.countdownEndDate
        self.isPaused = source.isPaused
        self.flipOffset = source.countdownFlipOffset
    }

    var body: some View {
        if isPaused {
            countdownText(at: .now)
        } else {
            TimelineView(.periodic(from: scheduleStart, by: 1)) { context in
                countdownText(at: context.date)
            }
        }
    }

    private var scheduleStart: Date {
        let now = Date.now
        guard let endDate else { return now }
        return TimerCountdownSchedule.start(endDate: endDate.addingTimeInterval(-flipOffset), now: now)
    }

    private func countdownText(at date: Date) -> some View {
        Text(source.formattedTime(at: date))
            .font(.system(size: 14, design: .rounded))
            .foregroundStyle(.orange.gradient)
            .monospacedDigit()
    }
}
