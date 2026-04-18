//
//  TimerCompactIndicatorView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/17/26.
//

import SwiftUI

struct TimerCompactIndicatorView: View {
    let snapshot: ClockTimerSnapshot

    private var ringSize: CGFloat { 18 }
    private var lineWidth: CGFloat { 3 }
    private var arrowSize: CGFloat { 6.5 }
    private var arrowOffset: CGFloat { 4.2 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: snapshot.isPaused)) { context in
            let progress = resolvedProgress(at: context.date)
            let angle = Angle.degrees((Double(progress) * 360) - 90)

            ZStack {
                Circle()
                    .fill(.white.opacity(0.04))

                Circle()
                    .stroke(.white.opacity(0.16), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.orange.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Circle()
                    .fill(.black.opacity(0.34))
                    .padding(lineWidth + 2)

                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: arrowSize, weight: .black))
                    .foregroundStyle(.orange.gradient)
                    .offset(y: -arrowOffset)
                    .rotationEffect(angle)
            }
            .frame(width: ringSize, height: ringSize)
        }
    }

    private func resolvedProgress(at date: Date) -> CGFloat {
        let rawProgress = CGFloat(snapshot.progress(at: date))
        guard snapshot.remainingTime(at: date) > 0 else { return 1 }
        guard snapshot.duration > 0 else { return 0 }

        if snapshot.isPaused {
            return max(0, min(rawProgress, 1))
        }

        return max(0.03, min(rawProgress, 1))
    }
}
