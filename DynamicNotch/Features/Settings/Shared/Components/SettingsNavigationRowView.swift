//
//  SettingsNavigationViewRow.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/13/26.
//

import SwiftUI

enum RowPosition {
    case first
    case middle
    case last
    case single
}

struct SettingsNavigationRowView<Value: Hashable>: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let systemImage: String?
    let imageName: String?
    let color: AnyShapeStyle
    let value: Value
    let accessibilityIdentifier: String?
    let position: RowPosition
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        color: Color = .blue,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        value: Value
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.imageName = nil
        self.color = AnyShapeStyle(color.gradient)
        self.value = value
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        imageName: String? = nil,
        color: Color = .blue,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        value: Value
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.color = AnyShapeStyle(color.gradient)
        self.value = value
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        color: LinearGradient,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        value: Value
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.imageName = nil
        self.color = AnyShapeStyle(color)
        self.value = value
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        imageName: String? = nil,
        color: LinearGradient,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        value: Value
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.color = AnyShapeStyle(color)
        self.value = value
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
    }

    var body: some View {
        VStack(spacing: 0) {
            if position != .first && position != .single {
                Divider()
                    .opacity(0.6)
                    .padding(.leading, 55)
                    .padding(.trailing, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
            NavigationLink(value: value) {
                HStack(alignment: .center, spacing: 12) {
                    if let systemImage {
                        SettingsIconBadge(
                            systemImage: systemImage,
                            tint: color,
                            size: 30,
                            iconSize: 14,
                            cornerRadius: 9
                        )
                    } else if let imageName {
                        SettingsIconBadge(
                            imageName: imageName,
                            tint: color,
                            size: 30,
                            iconSize: 14,
                            cornerRadius: 9
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.body)
                            .foregroundStyle(.primary)
                        if let description {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(NavigationCardButtonStyle(position: position))
        }
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}
