//
//  TimerCompactIndicatorView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/17/26.
//

import SwiftUI

struct TimerCompactIndicatorView: View {
    let source: TimerSource
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: source.isPaused)) { context in
            let progress = resolvedProgress(at: context.date)
            let angle = Self.handAngle(remainingFraction: progress)

            ZStack {
                circleIndicator(progress: progress)

                if source.isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange.gradient)
                } else {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(.orange.gradient)
                        .frame(width: 5, height: lineWidth)
                        .offset(x: 3.5)
                        .rotationEffect(angle)
                }
            }
            .frame(width: size, height: size)
        }
    }

    @ViewBuilder
    private func circleIndicator(progress: CGFloat) -> some View {
        Circle()
            .fill(.white.opacity(0.04))

        Circle()
            .stroke(.orange.opacity(0.32), lineWidth: lineWidth)

        Circle()
            .trim(from: 1 - progress, to: 1)
            .stroke(.orange.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .scaleEffect(x: -1, y: 1)

        Circle()
            .fill(.black.opacity(0.34))
            .padding(lineWidth + 2)
    }

    private func resolvedProgress(at date: Date) -> CGFloat {
        Self.ringFraction(
            elapsedFraction: source.progress(at: date),
            remaining: source.remainingTime(at: date),
            isPaused: source.isPaused
        )
    }

    /// The ring shows the time remaining, so it empties as the timer runs. A running timer stays
    /// between 3% and 92% filled until it ends. The 92% limit leaves a small dark gap past the
    /// round line caps from the start.
    /// The hand sweeps counterclockwise from the top as time passes and stays at the edge of the
    /// remaining arc.
    static func handAngle(remainingFraction: CGFloat) -> Angle {
        .degrees(-90 - 360 * Double(1 - remainingFraction))
    }

    static func ringFraction(elapsedFraction: Double, remaining: TimeInterval, isPaused: Bool) -> CGFloat {
        guard remaining > 0 else { return 0 }
        let remainingFraction = CGFloat(1 - min(max(elapsedFraction, 0), 1))
        return isPaused ? remainingFraction : min(max(0.03, remainingFraction), 0.92)
    }
}
