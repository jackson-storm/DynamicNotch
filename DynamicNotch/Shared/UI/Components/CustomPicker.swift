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
    let itemHeight: CGFloat
    let showsOptionTitle: Bool
    let lightBackgroundImage: Image?
    let darkBackgroundImage: Image?
    let backgroundImageContentMode: ContentMode
    let backgroundImageOpacity: Double
    private let content: (Option, Bool) -> AnyView
    
    init(
        selection: Binding<Option>,
        options: [Option],
        title: @escaping (Option) -> LocalizedStringKey,
        headerTitle: LocalizedStringKey? = nil,
        headerDescription: LocalizedStringKey? = nil,
        headerValueTitle: ((Option) -> LocalizedStringKey)? = nil,
        itemHeight: CGFloat = 62,
        showsOptionTitle: Bool = true,
        lightBackgroundImage: Image? = nil,
        darkBackgroundImage: Image? = nil,
        backgroundImageContentMode: ContentMode = .fill,
        backgroundImageOpacity: Double = 1,
        symbolName: @escaping (Option) -> String
    ) {
        self.init(
            selection: selection,
            options: options,
            title: title,
            headerTitle: headerTitle,
            headerDescription: headerDescription,
            headerValueTitle: headerValueTitle,
            itemHeight: itemHeight,
            showsOptionTitle: showsOptionTitle,
            lightBackgroundImage: lightBackgroundImage,
            darkBackgroundImage: darkBackgroundImage,
            backgroundImageContentMode: backgroundImageContentMode,
            backgroundImageOpacity: backgroundImageOpacity
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
        itemHeight: CGFloat = 62,
        showsOptionTitle: Bool = true,
        lightBackgroundImage: Image? = nil,
        darkBackgroundImage: Image? = nil,
        backgroundImageContentMode: ContentMode = .fill,
        backgroundImageOpacity: Double = 1,
        symbolName: @escaping (Option) -> String
    ) where Option: CaseIterable {
        self.init(
            selection: selection,
            options: Array(Option.allCases),
            title: title,
            headerTitle: headerTitle,
            headerDescription: headerDescription,
            headerValueTitle: headerValueTitle,
            itemHeight: itemHeight,
            showsOptionTitle: showsOptionTitle,
            lightBackgroundImage: lightBackgroundImage,
            darkBackgroundImage: darkBackgroundImage,
            backgroundImageContentMode: backgroundImageContentMode,
            backgroundImageOpacity: backgroundImageOpacity,
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
        itemHeight: CGFloat = 62,
        showsOptionTitle: Bool = true,
        lightBackgroundImage: Image? = nil,
        darkBackgroundImage: Image? = nil,
        backgroundImageContentMode: ContentMode = .fill,
        backgroundImageOpacity: Double = 1,
        @ViewBuilder content: @escaping (Option, Bool) -> Content
    ) {
        self._selection = selection
        self.options = options
        self.title = title
        self.headerTitle = headerTitle
        self.headerDescription = headerDescription
        self.headerValueTitle = headerValueTitle
        self.itemHeight = itemHeight
        self.showsOptionTitle = showsOptionTitle
        self.lightBackgroundImage = lightBackgroundImage
        self.darkBackgroundImage = darkBackgroundImage
        self.backgroundImageContentMode = backgroundImageContentMode
        self.backgroundImageOpacity = backgroundImageOpacity
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
        itemHeight: CGFloat = 62,
        showsOptionTitle: Bool = true,
        lightBackgroundImage: Image? = nil,
        darkBackgroundImage: Image? = nil,
        backgroundImageContentMode: ContentMode = .fill,
        backgroundImageOpacity: Double = 1,
        @ViewBuilder content: @escaping (Option, Bool) -> Content
    ) where Option: CaseIterable {
        self.init(
            selection: selection,
            options: Array(Option.allCases),
            title: title,
            headerTitle: headerTitle,
            headerDescription: headerDescription,
            headerValueTitle: headerValueTitle,
            itemHeight: itemHeight,
            showsOptionTitle: showsOptionTitle,
            lightBackgroundImage: lightBackgroundImage,
            darkBackgroundImage: darkBackgroundImage,
            backgroundImageContentMode: backgroundImageContentMode,
            backgroundImageOpacity: backgroundImageOpacity,
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
        
        VStack(spacing: showsOptionTitle ? 8 : 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selection = option
                }
            } label: {
                content(option, isSelected)
                    .frame(maxWidth: .infinity, minHeight: itemHeight, alignment: .center)
                    .padding(.horizontal, 12)
                    .background {
                        pickerCardBackground(isSelected: isSelected)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? Color.accentColor.opacity(0.9) : Color.gray.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            if showsOptionTitle {
                Text(title(option))
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
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

    @ViewBuilder
    private func pickerCardBackground(isSelected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        shape
            .fill(baseCardFillColor(isSelected: isSelected))
            .overlay {
                if let pickerBackgroundImage {
                    pickerBackgroundImage
                        .resizable()
                        .aspectRatio(contentMode: backgroundImageContentMode)
                        .opacity(backgroundImageOpacity)
                        .clipShape(shape)
                }
            }
            .overlay {
                if isSelected {
                    shape.fill(Color.accentColor.opacity(colorScheme == .dark ? 0.10 : 0.06))
                }
            }
            .clipShape(shape)
    }

    private func baseCardFillColor(isSelected: Bool) -> Color {
        return colorScheme == .dark ? Color.gray.opacity(0.08) : Color.gray.opacity(0.1)
    }

    private var pickerBackgroundImage: Image? {
        if colorScheme == .light, let lightBackgroundImage {
            return lightBackgroundImage
        }

        if colorScheme == .dark, let darkBackgroundImage {
            return darkBackgroundImage
        }

        return nil
    }
}
