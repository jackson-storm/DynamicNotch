//
//  SettingsUrlRowView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/14/26.
//

import SwiftUI

struct SettingsUrlRowView: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let systemImage: String?
    let imageName: String?
    let color: Color
    let url: String
    let accessibilityIdentifier: String?
    let position: RowPosition
    let onRequestInternetAccess: () -> Bool
    
    @Environment(\.openURL) private var openURL
    
    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        systemImage: String? = nil,
        color: Color = .blue,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        url: String,
        onRequestInternetAccess: @escaping () -> Bool
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.imageName = nil
        self.color = color
        self.url = url
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
        self.onRequestInternetAccess = onRequestInternetAccess
    }

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        imageName: String? = nil,
        color: Color = .blue,
        accessibilityIdentifier: String? = nil,
        position: RowPosition = .single,
        url: String,
        onRequestInternetAccess: @escaping () -> Bool
    ) {
        self.title = title
        self.description = description
        self.systemImage = nil
        self.imageName = imageName
        self.color = color
        self.url = url
        self.accessibilityIdentifier = accessibilityIdentifier
        self.position = position
        self.onRequestInternetAccess = onRequestInternetAccess
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
                if let targetUrl = URL(string: url) {
                    if onRequestInternetAccess() {
                        openURL(targetUrl)
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
                    
                    Image(systemName: "arrow.up.right")
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
