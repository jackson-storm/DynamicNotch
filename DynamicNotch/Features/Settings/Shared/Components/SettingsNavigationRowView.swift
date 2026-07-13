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
    let color: Color
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
        self.color = color
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
        self.color = color
        self.value = value
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
    }

    var body: some View {
        VStack(spacing: 0) {
            if position != .first {
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
            .buttonStyle(SettingsNavigationCardButtonStyle(position: position))
        }
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}

private struct SettingsNavigationCardButtonStyle: ButtonStyle {
    let position: RowPosition
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("settings.general.isBlueNightMode") private var isBlueNightMode = false
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                shape
                    .fill(overlayColor(isPressed: configuration.isPressed))
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }

    private var shape: UnevenRoundedRectangle {
        switch position {
        case .first:
            return UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16, style: .continuous)
        case .middle:
            return UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
        case .last:
            return UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 0, style: .continuous)
        case .single:
            return UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 16, style: .continuous)
        }
    }

    private func overlayColor(isPressed: Bool) -> Color {
        if isPressed {
            return Color.primary.opacity(0.1)
        } else if isHovered {
            return Color.primary.opacity(0.06)
        } else {
            return Color.clear
        }
    }
}
