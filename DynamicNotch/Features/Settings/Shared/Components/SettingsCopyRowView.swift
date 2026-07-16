//
//  SettingsCopyRowView.swift
//  DynamicNotch
//
//  Created by Antigravity on 7/16/26.
//

import SwiftUI
internal import AppKit

struct SettingsCopyRowView: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let systemImage: String?
    let imageName: String?
    let imageSize: CGFloat
    let color: AnyShapeStyle
    let cornerRadius: CGFloat
    let stroke: Bool
    let textToCopy: String
    let accessibilityIdentifier: String?
    let position: RowPosition
    
    @State private var isCopied = false
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        imageSize: CGFloat = 30,
        color: Color = .blue,
        cornerRadius: CGFloat = 9,
        stroke: Bool = false,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        textToCopy: String
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.imageName = nil
        self.imageSize = imageSize
        self.color = AnyShapeStyle(color.gradient)
        self.cornerRadius = cornerRadius
        self.stroke = stroke
        self.textToCopy = textToCopy
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        imageName: String? = nil,
        imageSize: CGFloat = 30,
        color: Color = .blue,
        cornerRadius: CGFloat = 9,
        stroke: Bool = false,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        textToCopy: String
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.imageSize = imageSize
        self.color = AnyShapeStyle(color.gradient)
        self.cornerRadius = cornerRadius
        self.stroke = stroke
        self.textToCopy = textToCopy
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        imageSize: CGFloat = 30,
        color: LinearGradient,
        cornerRadius: CGFloat = 9,
        stroke: Bool = false,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        textToCopy: String
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.imageName = nil
        self.imageSize = imageSize
        self.color = AnyShapeStyle(color)
        self.cornerRadius = cornerRadius
        self.stroke = stroke
        self.textToCopy = textToCopy
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        imageName: String? = nil,
        imageSize: CGFloat = 30,
        color: LinearGradient,
        cornerRadius: CGFloat = 9,
        stroke: Bool = false,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        textToCopy: String
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.imageSize = imageSize
        self.color = AnyShapeStyle(color)
        self.cornerRadius = cornerRadius
        self.stroke = stroke
        self.textToCopy = textToCopy
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
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(textToCopy, forType: .string)
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isCopied = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isCopied = false
                    }
                }
            }) {
                HStack(alignment: .center, spacing: 12) {
                    if let systemImage {
                        SettingsIconBadge(
                            systemImage: systemImage,
                            tint: color,
                            size: 30,
                            iconSize: 14,
                            cornerRadius: cornerRadius,
                            stroke: stroke
                        )
                    } else if let imageName {
                        SettingsIconBadge(
                            imageName: imageName,
                            tint: color,
                            size: 30,
                            iconSize: imageSize,
                            cornerRadius: cornerRadius,
                            stroke: stroke
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
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    Spacer()
                    
                    if isCopied {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(NavigationCardButtonStyle(position: position))
        }
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}
