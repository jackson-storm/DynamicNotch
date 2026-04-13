//
//  DownloadProgressIndicatorView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct DownloadProgressIndicatorView: View {
    let progress: Double
    let indicatorStyle: DownloadProgressIndicatorStyle
    let barWidth: CGFloat
    let barHeight: CGFloat
    let circleSize: CGFloat
    let circleLineWidth: CGFloat
    let percentFontSize: CGFloat

    private var clampedProgress: CGFloat {
        max(0.06, min(CGFloat(progress), 1))
    }
    
    var body: some View {
        Group {
            switch indicatorStyle {
            case .percent:
                Text("\(Int((clampedProgress * 100).rounded()))%")
                    .font(.system(size: percentFontSize))
                    .foregroundStyle(Color.accentColor.gradient)

            case .circle:
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: circleLineWidth)
                    
                    Circle()
                        .trim(from: 0, to: clampedProgress)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    .accentColor.opacity(0.3),
                                    .accentColor.opacity(0.9),
                                    .accentColor
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(
                                lineWidth: circleLineWidth,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: circleSize, height: circleSize)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: clampedProgress)
    }
}
