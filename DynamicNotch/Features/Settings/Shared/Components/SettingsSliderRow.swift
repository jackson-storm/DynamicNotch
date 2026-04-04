//
//  SliderRow.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsSliderRow: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let range: ClosedRange<Double>
    let step: Double
    let fractionLength: Int
    let suffix: String?
    let accessibilityIdentifier: String?
    
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                AnimatedLevelText(
                    value: value,
                    fontSize: 12,
                    fractionLength: fractionLength,
                    suffix: suffix,
                    color: .secondary
                )
            }
            
            Slider(value: $value, in: range, step: step)
        }
        .padding(10)
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}
