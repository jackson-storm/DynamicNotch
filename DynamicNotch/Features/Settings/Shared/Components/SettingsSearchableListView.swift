//
//  SettingsSearchableListView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 8/18/26.
//

import SwiftUI

struct SettingsSearchableListView<Item: Identifiable & Hashable, LeadingAccessory: View>: View {
    let items: [Item]
    @Binding var selection: Item
    
    let title: (Item) -> LocalizedStringKey
    let subtitle: ((Item) -> String?)?
    let matchesQuery: (Item, String) -> Bool
    let accessibilityIdentifier: ((Item) -> String)?
    let leadingAccessory: (Item) -> LeadingAccessory
    
    @State private var searchText: String = ""
    
    init(
        items: [Item],
        selection: Binding<Item>,
        title: @escaping (Item) -> LocalizedStringKey,
        subtitle: ((Item) -> String?)? = nil,
        matchesQuery: @escaping (Item, String) -> Bool,
        accessibilityIdentifier: ((Item) -> String)? = nil,
        @ViewBuilder leadingAccessory: @escaping (Item) -> LeadingAccessory
    ) {
        self.items = items
        self._selection = selection
        self.title = title
        self.subtitle = subtitle
        self.matchesQuery = matchesQuery
        self.accessibilityIdentifier = accessibilityIdentifier
        self.leadingAccessory = leadingAccessory
    }
    
    private var filteredItems: [Item] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return items }
        return items.filter { matchesQuery($0, query) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(10)
            
            Divider()
                .opacity(0.6)
                .padding(.horizontal, 10)
            
            if filteredItems.isEmpty {
                emptySearchState
            } else {
                itemList
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            
            TextField(LocalizedStringKey("settings.search.prompt"), text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                }
        }
        .accessibilityIdentifier("settings.searchableList.search")
    }
    
    private var itemList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(filteredItems.enumerated()), id: \.element) { index, item in
                if index > 0 {
                    Divider()
                        .opacity(0.6)
                        .padding(.leading, 53)
                        .padding(.trailing, 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }
                
                itemRow(
                    for: item,
                    position: rowPosition(for: index, total: filteredItems.count)
                )
            }
        }
    }
    
    private func rowPosition(for index: Int, total: Int) -> RowPosition {
        return .middle
    }
    
    private func itemRow(for item: Item, position: RowPosition) -> some View {
        let isSelected = item == selection
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = item
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                leadingAccessory(item)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title(item))
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if let subtitle = subtitle?(item), !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(NavigationCardButtonStyle(position: position))
        .modifier(SettingsAccessibilityModifier(identifier: accessibilityIdentifier?(item)))
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            
            Text(LocalizedStringKey("settings.search.empty.title"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
