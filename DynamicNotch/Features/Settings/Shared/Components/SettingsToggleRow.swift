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
    let systemImage: String?
    let imageName: String?
    let color: AnyShapeStyle
    let stroke: Bool
    let accessibilityIdentifier: String?
    
    @Binding var isOn: Bool
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        systemImage: String,
        color: Color,
        stroke: Bool = false,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.imageName = nil
        self.color = AnyShapeStyle(color.gradient)
        self.stroke = stroke
        self._isOn = isOn
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        imageName: String,
        color: Color,
        stroke: Bool = false,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.color = AnyShapeStyle(color.gradient)
        self.stroke = stroke
        self._isOn = isOn
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        systemImage: String,
        color: LinearGradient,
        stroke: Bool = false,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.imageName = nil
        self.color = AnyShapeStyle(color)
        self.stroke = stroke
        self._isOn = isOn
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        imageName: String,
        color: LinearGradient,
        stroke: Bool = false,
        isOn: Binding<Bool>,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.color = AnyShapeStyle(color)
        self.stroke = stroke
        self._isOn = isOn
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .center, spacing: 12) {
                if let systemImage {
                    SettingsIconBadge(
                        systemImage: systemImage,
                        tint: color,
                        size: 30,
                        iconSize: 14,
                        cornerRadius: 9,
                        stroke: stroke
                    )
                } else if let imageName {
                    SettingsIconBadge(
                        imageName: imageName,
                        tint: color,
                        size: 30,
                        iconSize: 14,
                        cornerRadius: 9,
                        stroke: stroke
                    )
                }
                
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
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}
