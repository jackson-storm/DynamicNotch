//
//  SettingsToggleRow.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsToggleRow: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let systemImage: String
    let color: Color
    let accessibilityIdentifier: String?
    
    @Binding var isOn: Bool
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        systemImage: String,
        color: Color,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.color = color
        self._isOn = isOn
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .center, spacing: 12) {
                SettingsIconBadge(
                    systemImage: systemImage,
                    tint: color,
                    size: 30,
                    iconSize: 14,
                    cornerRadius: 9
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
        }
        .toggleStyle(CustomToggleStyle())
        .padding(10)
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}
