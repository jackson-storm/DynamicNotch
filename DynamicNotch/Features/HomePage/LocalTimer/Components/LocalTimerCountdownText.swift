//
//  LocalTimerCountdownText.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 5/20/26.
//

import SwiftUI

struct LocalTimerCountdownText: View {
    @ObservedObject var viewModel: LocalTimerViewModel

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.25, paused: viewModel.state == .paused || viewModel.state == .stopped)) { context in
            let remaining = viewModel.remainingTime(at: context.date)
            let formatted = viewModel.formatTime(remaining)
            Text(formatted)
                .font(.system(size: 14, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.28, extraBounce: 0.12), value: formatted)
        }
    }
}
