//
//  AnimateLevelText.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/29/26.
//

import SwiftUI

struct AnimatedLevelText: View {
    private let value: Double
    private let fractionLength: Int
    private let fontSize: CGFloat
    private let suffix: String?
    private let color: Color

    init(
        level: Int,
        fontSize: CGFloat,
        suffix: String? = nil,
        color: Color = .white.opacity(0.8)
    ) {
        self.value = Double(level)
        self.fractionLength = 0
        self.fontSize = fontSize
        self.suffix = suffix
        self.color = color
    }

    init(
        value: Double,
        fontSize: CGFloat,
        fractionLength: Int = 0,
        suffix: String? = nil,
        color: Color = .white.opacity(0.8)
    ) {
        self.value = value
        self.fractionLength = fractionLength
        self.fontSize = fontSize
        self.suffix = suffix
        self.color = color
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: suffix == nil ? 0 : 4) {
            Text(value, format: .number.precision(.fractionLength(fractionLength)))
                .font(.system(size: fontSize, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.28, extraBounce: 0.12), value: value)

            if let suffix {
                Text(suffix)
                    .font(.system(size: fontSize, design: .rounded))
                    .foregroundStyle(color)
            }
        }
    }
}
