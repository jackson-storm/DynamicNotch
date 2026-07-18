//
//  SettingsButtonRow.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/18/26.
//

import SwiftUI

struct SettingsButtonRow: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let systemImage: String?
    let imageName: String?
    let iconSize: CGFloat
    let color: AnyShapeStyle
    let stroke: Bool
    let accessibilityIdentifier: String?
    
    let buttonTitle: LocalizedStringKey
    let isButtonDisabled: Bool
    let action: () -> Void
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        systemImage: String,
        iconSize: CGFloat = 14,
        color: Color,
        stroke: Bool = false,
        buttonTitle: LocalizedStringKey,
        isButtonDisabled: Bool = false,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.imageName = nil
        self.iconSize = iconSize
        self.color = AnyShapeStyle(color.gradient)
        self.stroke = stroke
        self.buttonTitle = buttonTitle
        self.isButtonDisabled = isButtonDisabled
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        imageName: String,
        iconSize: CGFloat = 14,
        color: Color,
        stroke: Bool = false,
        buttonTitle: LocalizedStringKey,
        isButtonDisabled: Bool = false,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.iconSize = iconSize
        self.color = AnyShapeStyle(color.gradient)
        self.stroke = stroke
        self.buttonTitle = buttonTitle
        self.isButtonDisabled = isButtonDisabled
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        systemImage: String,
        iconSize: CGFloat = 14,
        color: LinearGradient,
        stroke: Bool = false,
        buttonTitle: LocalizedStringKey,
        isButtonDisabled: Bool = false,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.iconSize = iconSize
        self.imageName = nil
        self.color = AnyShapeStyle(color)
        self.stroke = stroke
        self.buttonTitle = buttonTitle
        self.isButtonDisabled = isButtonDisabled
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        imageName: String,
        iconSize: CGFloat = 14,
        color: LinearGradient,
        stroke: Bool = false,
        buttonTitle: LocalizedStringKey,
        isButtonDisabled: Bool = false,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.iconSize = iconSize
        self.color = AnyShapeStyle(color)
        self.stroke = stroke
        self.buttonTitle = buttonTitle
        self.isButtonDisabled = isButtonDisabled
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }
    
    var body: some View {
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
                    iconSize: iconSize,
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
            
            Button(action: action) {
                Text(buttonTitle)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(isButtonDisabled)
        }
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}
