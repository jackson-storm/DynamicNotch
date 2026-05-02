//
//  BluetoothBatteryIndicatorView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/14/26.
//

import SwiftUI

struct BluetoothBatteryIndicatorView: View {
    let batteryLevel: Int?
    let circleSize: CGFloat
    let circleLineWidth: CGFloat
    var usesTintedTrackStroke: Bool = false
    
    private var clampedLevel: Int? {
        batteryLevel.map { max(0, min(100, $0)) }
    }
    
    private func tint(for level: Int) -> Color {
        if level < 20 { return .red }
        if level < 50 { return .yellow }
        return .green
    }
    
    private func progress(for level: Int) -> CGFloat {
        CGFloat(level) / 100
    }
    
    private func trackStrokeColor(for level: Int) -> Color {
        return tint(for: level).opacity(0.2)
    }
    
    var body: some View {
        if let clampedLevel {
            ZStack {
                Circle()
                    .fill(.clear)
                
                Circle()
                    .stroke(trackStrokeColor(for: clampedLevel), lineWidth: circleLineWidth)
                
                Circle()
                    .trim(from: 0, to: progress(for: clampedLevel))
                    .stroke(
                        tint(for: clampedLevel).gradient,
                        style: StrokeStyle(lineWidth: circleLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: tint(for: clampedLevel).opacity(0.35), radius: 5, y: 0)
            }
            .frame(width: circleSize, height: circleSize)
            
        } else {
            Text("---")
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
