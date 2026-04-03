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
    private let content: (Option, Bool) -> AnyView
    
    init(
        selection: Binding<Option>,
        options: [Option],
        title: @escaping (Option) -> LocalizedStringKey,
        symbolName: @escaping (Option) -> String
    ) {
        self.init(
            selection: selection,
            options: options,
            title: title
        ) { option, isSelected in
            Image(systemName: symbolName(option))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
    }
    
    init(
        selection: Binding<Option>,
        title: @escaping (Option) -> LocalizedStringKey,
        symbolName: @escaping (Option) -> String
    ) where Option: CaseIterable {
        self.init(
            selection: selection,
            options: Array(Option.allCases),
            title: title,
            symbolName: symbolName
        )
    }

    init<Content: View>(
        selection: Binding<Option>,
        options: [Option],
        title: @escaping (Option) -> LocalizedStringKey,
        @ViewBuilder content: @escaping (Option, Bool) -> Content
    ) {
        self._selection = selection
        self.options = options
        self.title = title
        self.content = { option, isSelected in
            AnyView(content(option, isSelected))
        }
    }

    init<Content: View>(
        selection: Binding<Option>,
        title: @escaping (Option) -> LocalizedStringKey,
        @ViewBuilder content: @escaping (Option, Bool) -> Content
    ) where Option: CaseIterable {
        self.init(
            selection: selection,
            options: Array(Option.allCases),
            title: title,
            content: content
        )
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                card(for: option)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                            (colorScheme == .dark ? Color.gray.opacity(0.08) : Color.gray.opacity(0.18))
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
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
