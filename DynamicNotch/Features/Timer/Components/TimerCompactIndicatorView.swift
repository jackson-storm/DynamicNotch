//
//  TimerCompactIndicatorView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/17/26.
//

import SwiftUI

struct TimerCompactIndicatorView: View {
    let source: TimerSource
    
    @Environment(\.isNotchlessScreen) private var isNotchlessScreen
    
    private var lineWidth: CGFloat { 2.8 }
    private var cornerRadius: CGFloat { 5 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: source.isPaused)) { context in
            let progress = resolvedProgress(at: context.date)
            let angle = Angle.degrees((-Double(progress) * 360) - 90)

            ZStack {
                if isNotchlessScreen {
                    circleIndicator(progress: progress)
                } else {
                    roundedRectangleIndicator(progress: progress)
                }

                if source.isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange.gradient)
                } else {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(.orange.gradient)
                        .frame(width: 6, height: 2.5)
                        .offset(x: 3.5)
                        .rotationEffect(angle)
                }
            }
            .frame(width: 20, height: 20)
        }
    }

    @ViewBuilder
    private func circleIndicator(progress: CGFloat) -> some View {
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
    }

    @ViewBuilder
    private func roundedRectangleIndicator(progress: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.white.opacity(0.04))

        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(.white.opacity(0.16), lineWidth: lineWidth)

        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .trim(from: 0, to: progress)
            .stroke(.orange.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .scaleEffect(x: -1, y: 1)

        RoundedRectangle(cornerRadius: max(1, cornerRadius - 2.5), style: .continuous)
            .fill(.black.opacity(0.34))
            .padding(lineWidth + 2)
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
