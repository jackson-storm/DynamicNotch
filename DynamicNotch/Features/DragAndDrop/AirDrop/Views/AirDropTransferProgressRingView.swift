//
//  AirDropTransferProgressRingView.swift
//  DynamicNotch
//

import SwiftUI

struct AirDropTransferProgressRingView: View {
    let progress: Double
    var size: CGFloat = 26
    var lineWidth: CGFloat = 2.5
    var ringColor: Color = .blue
    var stopSquareSize: CGFloat = 8

    @State private var isHovered = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(max(0.02, min(1.0, progress))))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(ringColor)
                    .frame(width: stopSquareSize, height: stopSquareSize)
        }
        .frame(width: size, height: size)
    }
}
