//
//  TimerCompactIndicatorView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/17/26.
//

import SwiftUI

struct TimerCompactIndicatorView: View {
    let source: TimerSource
    
    @Environment(\.isDynamicIsland) private var isDynamicIsland
    
    private var lineWidth: CGFloat { 2.5 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: source.isPaused)) { context in
            let progress = resolvedProgress(at: context.date)
            let angle = Angle.degrees((-Double(progress) * 360) - 90)

            ZStack {
                Circle()
                    .fill(.white.opacity(0.04))

                Circle()
                    .stroke(.white.opacity(0.16), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.orange.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(x: -1, y: 1)

                Circle()
                    .fill(.black.opacity(0.34))
                    .padding(lineWidth + 2)

                RoundedRectangle(cornerRadius: 1)
                    .fill(.orange.gradient)
                    .frame(width: 6, height: 2.5)
                    .offset(x: 3.5)
                    .rotationEffect(angle)
            }
            .frame(width: isDynamicIsland ? 16 : 20, height: isDynamicIsland ? 16: 20)
        }
    }

    private func resolvedProgress(at date: Date) -> CGFloat {
        let rawProgress = CGFloat(source.progress(at: date))
        let remaining = source.remainingTime(at: date)
        guard remaining > 0 else { return 1 }

        if source.isPaused {
            return max(0, min(rawProgress, 1))
        }
        return max(0.03, min(rawProgress, 1))
    }
}
