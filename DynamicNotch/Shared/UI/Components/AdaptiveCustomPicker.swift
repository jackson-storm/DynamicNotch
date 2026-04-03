//
//  AdaptiveCustomPicker.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/3/26.
//

import SwiftUI

struct AdaptiveCustomPicker<Option: Hashable>: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @Binding var selection: Option
    let options: [Option]
    let title: (Option) -> LocalizedStringKey
    let minimumItemWidth: CGFloat
    let maximumItemWidth: CGFloat
    private let accessibilityIdentifier: ((Option) -> String?)?
    private let content: (Option, Bool) -> AnyView

    init<Content: View>(
        selection: Binding<Option>,
        options: [Option],
        minimumItemWidth: CGFloat = 88,
        maximumItemWidth: CGFloat = 104,
        title: @escaping (Option) -> LocalizedStringKey,
        accessibilityIdentifier: ((Option) -> String?)? = nil,
        @ViewBuilder content: @escaping (Option, Bool) -> Content
    ) {
        self._selection = selection
        self.options = options
        self.title = title
        self.minimumItemWidth = minimumItemWidth
        self.maximumItemWidth = maximumItemWidth
        self.accessibilityIdentifier = accessibilityIdentifier
        self.content = { option, isSelected in
            AnyView(content(option, isSelected))
        }
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumItemWidth, maximum: maximumItemWidth), spacing: 12)],
            spacing: 12
        ) {
            ForEach(options, id: \.self) { option in
                card(for: option)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func card(for option: Option) -> some View {
        let isSelected = selection == option

        VStack(spacing: 8) {
            pickerButton(for: option, isSelected: isSelected)

            Text(title(option))
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    @ViewBuilder
    private func pickerButton(for option: Option, isSelected: Bool) -> some View {
        let button = Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = option
            }
        } label: {
            let cardShape = RoundedRectangle(cornerRadius: 10, style: .continuous)

            content(option, isSelected)
                .frame(maxWidth: .infinity, minHeight: 62, alignment: .center)
                .padding(.horizontal, 12)
                .background(
                    cardShape
                        .fill(
                            isSelected ?
                            Color.accentColor.opacity(colorScheme == .dark ? 0.10 : 0.06) :
                            (colorScheme == .dark ? Color.gray.opacity(0.08) : Color.gray.opacity(0.18))
                        )
                )
                .clipShape(cardShape)
                .overlay(
                    cardShape
                        .stroke(isSelected ? Color.accentColor.opacity(0.9) : Color.gray.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
                .contentShape(cardShape)
        }
        .buttonStyle(.plain)

        if let accessibilityIdentifier = accessibilityIdentifier?(option) {
            button.accessibilityIdentifier(accessibilityIdentifier)
        } else {
            button
        }
    }
}
