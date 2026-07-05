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
            CircleIndicatorView(
                progress: progress(for: clampedLevel),
                size: circleSize,
                lineWidth: circleLineWidth,
                trackStrokeColor: trackStrokeColor(for: clampedLevel),
                fillBackground: .clear,
                foregroundStyle: tint(for: clampedLevel).gradient,
                glowColor: tint(for: clampedLevel).opacity(0.35),
                glowRadius: 5,
                glowY: 0
            )
        } else {
            Text("---")
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
