//
//  SettingsChoiceRow.swift
//  DynamicNotch
//
//  Created by Antigravity on 7/9/26.
//

import SwiftUI

struct SettingsChoiceRow: View {
    let title: String
    let description: String
    let statusText: String
    var statusColor: Color = .secondary
    var errorText: String? = nil
    
    let chooseButtonTitle: String
    let onChoose: () -> Void
    
    var onReset: (() -> Void)? = nil
    var accessibilityIdentifier: String? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let errorText {
                    Text(errorText)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if let onReset {
                    Button("Reset") {
                        onReset()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier(accessibilityIdentifier != nil ? "\(accessibilityIdentifier!).reset" : "")
                }

                Button(chooseButtonTitle) {
                    onChoose()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityIdentifier(accessibilityIdentifier != nil ? "\(accessibilityIdentifier!).choose" : "")
            }
        }
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier))
    }
}
