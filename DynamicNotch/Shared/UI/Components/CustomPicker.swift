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
    let title: (Option) -> String
    let symbolName: (Option) -> String
    
    init(
        selection: Binding<Option>,
        options: [Option],
        title: @escaping (Option) -> String,
        symbolName: @escaping (Option) -> String
    ) {
        self._selection = selection
        self.options = options
        self.title = title
        self.symbolName = symbolName
    }
    
    init(
        selection: Binding<Option>,
        title: @escaping (Option) -> String,
        symbolName: @escaping (Option) -> String
    ) where Option: CaseIterable {
        self._selection = selection
        self.options = Array(Option.allCases)
        self.title = title
        self.symbolName = symbolName
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
                HStack(spacing: 10) {
                    Image(systemName: symbolName(option))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 62, alignment: .center)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(colorScheme == .dark ? Color.gray.opacity(isSelected ? 0.12 : 0.08) : Color .gray.opacity(isSelected ? 0.22 : 0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Color.blue.opacity(0.9) : Color.gray.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            
            Text(title(option))
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
