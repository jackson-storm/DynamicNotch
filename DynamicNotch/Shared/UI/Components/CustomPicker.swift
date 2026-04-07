//
//  CustomPicker.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 3/8/26.
//

import SwiftUI

struct CustomPicker<Option: Hashable>: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @Binding var selection: Option
    let options: [Option]
    let title: (Option) -> LocalizedStringKey
    let headerTitle: LocalizedStringKey?
    let headerDescription: LocalizedStringKey?
    let headerValueTitle: ((Option) -> LocalizedStringKey)?
    private let content: (Option, Bool) -> AnyView
    
    init(
        selection: Binding<Option>,
        options: [Option],
        title: @escaping (Option) -> LocalizedStringKey,
        headerTitle: LocalizedStringKey? = nil,
        headerDescription: LocalizedStringKey? = nil,
        headerValueTitle: ((Option) -> LocalizedStringKey)? = nil,
        symbolName: @escaping (Option) -> String
    ) {
        self.init(
            selection: selection,
            options: options,
            title: title,
            headerTitle: headerTitle,
            headerDescription: headerDescription,
            headerValueTitle: headerValueTitle
        ) { option, isSelected in
            Image(systemName: symbolName(option))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
    }
    
    init(
        selection: Binding<Option>,
        title: @escaping (Option) -> LocalizedStringKey,
        headerTitle: LocalizedStringKey? = nil,
        headerDescription: LocalizedStringKey? = nil,
        headerValueTitle: ((Option) -> LocalizedStringKey)? = nil,
        symbolName: @escaping (Option) -> String
    ) where Option: CaseIterable {
        self.init(
            selection: selection,
            options: Array(Option.allCases),
            title: title,
            headerTitle: headerTitle,
            headerDescription: headerDescription,
            headerValueTitle: headerValueTitle,
            symbolName: symbolName
        )
    }

    init<Content: View>(
        selection: Binding<Option>,
        options: [Option],
        title: @escaping (Option) -> LocalizedStringKey,
        headerTitle: LocalizedStringKey? = nil,
        headerDescription: LocalizedStringKey? = nil,
        headerValueTitle: ((Option) -> LocalizedStringKey)? = nil,
        @ViewBuilder content: @escaping (Option, Bool) -> Content
    ) {
        self._selection = selection
        self.options = options
        self.title = title
        self.headerTitle = headerTitle
        self.headerDescription = headerDescription
        self.headerValueTitle = headerValueTitle
        self.content = { option, isSelected in
            AnyView(content(option, isSelected))
        }
    }

    init<Content: View>(
        selection: Binding<Option>,
        title: @escaping (Option) -> LocalizedStringKey,
        headerTitle: LocalizedStringKey? = nil,
        headerDescription: LocalizedStringKey? = nil,
        headerValueTitle: ((Option) -> LocalizedStringKey)? = nil,
        @ViewBuilder content: @escaping (Option, Bool) -> Content
    ) where Option: CaseIterable {
        self.init(
            selection: selection,
            options: Array(Option.allCases),
            title: title,
            headerTitle: headerTitle,
            headerDescription: headerDescription,
            headerValueTitle: headerValueTitle,
            content: content
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let headerTitle {
                pickerHeader(title: headerTitle)
            }
            
            HStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    card(for: option)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func card(for option: Option) -> some View {
        let isSelected = selection == option
        
        VStack {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selection = option
                }
            } label: {
                content(option, isSelected)
                .frame(maxWidth: .infinity, minHeight: 62, alignment: .center)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            isSelected ?
                            Color.accentColor.opacity(colorScheme == .dark ? 0.10 : 0.06) :
                            (colorScheme == .dark ? Color.gray.opacity(0.08) : Color.gray.opacity(0.1))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Color.accentColor.opacity(0.9) : Color.gray.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            
            Text(title(option))
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
    
    @ViewBuilder
    private func pickerHeader(title: LocalizedStringKey) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                
                if let headerDescription {
                    Text(headerDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 12)
            
            Text(selectedHeaderValueTitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
    
    private var selectedHeaderValueTitle: LocalizedStringKey {
        headerValueTitle?(selection) ?? title(selection)
    }
}
