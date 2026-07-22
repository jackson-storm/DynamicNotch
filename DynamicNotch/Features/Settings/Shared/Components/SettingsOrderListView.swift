//
//  SettingsOrderListView.swift
//  DynamicNotch
//
//  Created by Antigravity on 7/9/26.
//

import SwiftUI

struct SettingsOrderListView<Item: Hashable>: View {
    @Binding var items: [Item]
    @Binding var disabledItems: Set<Item>
    
    let icon: (Item) -> String
    let tint: (Item) -> Color
    let iconTint: (Item) -> Color
    let title: (Item) -> LocalizedStringKey
    let subtitle: (Item) -> LocalizedStringKey
    
    var isListEnabled: Bool = true

    var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 12) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.system(size: 14))

                    SettingsIconBadge(
                        systemImage: icon(item),
                        tint: tint(item),
                        size: 30,
                        iconColor: iconTint(item),
                        iconSize: 14,
                        cornerRadius: 9
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title(item))
                        Text(subtitle(item))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { !disabledItems.contains(item) },
                        set: { isEnabled in
                            if isEnabled {
                                disabledItems.remove(item)
                            } else {
                                disabledItems.insert(item)
                            }
                        }
                    ))
                    .labelsHidden()
                }
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(.gray.opacity(0.1))
            }
            .onMove { from, to in
                items.move(fromOffsets: from, toOffset: to)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .frame(height: CGFloat(items.count) * 52)
        .disabled(!isListEnabled)
        .opacity(isListEnabled ? 1.0 : 0.5)
    }
}
