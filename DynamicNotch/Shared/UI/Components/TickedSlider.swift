//
//  TickedSlider.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/8/26.
//

import SwiftUI

struct TickedSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Int>
    let step: Double
    var tickCount: Double? = nil
    var valueFormatter: (Double) -> String = { "\($0)" }
    
    private var doubleBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(value) },
            set: { newVal in
                let stepped = round(newVal / Double(step)) * Double(step)
                let clamped = min(max(stepped, Double(range.lowerBound)), Double(range.upperBound))
                value = Double(clamped)
            }
        )
    }
    
    private var totalTicks: Int {
        if let tickCount { return Int(max(tickCount, 2)) }
        return range.upperBound - range.lowerBound + 1
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                ValuePill(text: valueFormatter(value))
            }
            
            Slider(
                value: doubleBinding,
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(.accentColor)
            .labelsHidden()
            .frame(height: 24)
        }
    }
    
    private struct ValuePill: View {
        let text: String
        var body: some View {
            Text(text)
                .font(.system(size: 12))
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.gray.opacity(0.18))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                )
                .foregroundStyle(.secondary)
        }
    }
}
