//
//  CircleIndicatorView.swift
//  DynamicNotch
//
//  Created by Antigravity on 7/5/26.
//

import SwiftUI

struct CircleIndicatorView: View {
    let progress: CGFloat
    let size: CGFloat
    let lineWidth: CGFloat
    let trackStrokeColor: Color
    let fillBackground: Color
    let foregroundStyle: AnyShapeStyle
    let glowColor: Color
    let glowRadius: CGFloat
    let glowY: CGFloat

    init(
        progress: CGFloat,
        size: CGFloat = 16,
        lineWidth: CGFloat = 3,
        trackStrokeColor: Color = Color.white.opacity(0.16),
        fillBackground: Color = Color.white.opacity(0.04),
        foregroundStyle: AnyShapeStyle,
        glowColor: Color = .clear,
        glowRadius: CGFloat = 0,
        glowY: CGFloat = 0
    ) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.trackStrokeColor = trackStrokeColor
        self.fillBackground = fillBackground
        self.foregroundStyle = foregroundStyle
        self.glowColor = glowColor
        self.glowRadius = glowRadius
        self.glowY = glowY
    }

    init<S: ShapeStyle>(
        progress: CGFloat,
        size: CGFloat = 16,
        lineWidth: CGFloat = 3,
        trackStrokeColor: Color = Color.white.opacity(0.16),
        fillBackground: Color = Color.white.opacity(0.04),
        foregroundStyle: S,
        glowColor: Color = .clear,
        glowRadius: CGFloat = 0,
        glowY: CGFloat = 0
    ) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.trackStrokeColor = trackStrokeColor
        self.fillBackground = fillBackground
        self.foregroundStyle = AnyShapeStyle(foregroundStyle)
        self.glowColor = glowColor
        self.glowRadius = glowRadius
        self.glowY = glowY
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fillBackground)

            Circle()
                .stroke(trackStrokeColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    foregroundStyle,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: glowColor, radius: glowRadius, x: 0, y: glowY)
        }
        .frame(width: size, height: size)
    }
}
