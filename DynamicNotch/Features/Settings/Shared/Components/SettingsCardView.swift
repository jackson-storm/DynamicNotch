//
//  SettingsCardView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsCard<Content: View>: View {
    let title: LocalizedStringKey?
    
    private let content: Content
    
    init(
        title: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            
        } label: {
            if let title {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                }
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 10)
        .groupBoxStyle(SettingsCardGroupBoxStyle())
    }
}

private struct SettingsCardGroupBoxStyle: GroupBoxStyle {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("settings.general.isBlueNightMode") private var isBlueNightMode = false
    @AppStorage("settings.general.window.style") private var windowStyle = SettingsWindowStyle.regular.rawValue

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            configuration.label
                .padding(.leading, 15)
            configuration.content
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(cardFillStyle)
                        .overlay {
                            if windowStyle == SettingsWindowStyle.semiTranslucent.rawValue {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2), lineWidth: 0.5)
                            }
                        }
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardFillStyle: AnyShapeStyle {
        if windowStyle == SettingsWindowStyle.semiTranslucent.rawValue {
            return AnyShapeStyle(colorScheme == .dark ? .black.opacity(0.2) : .white.opacity(0.8))
        } else if isBlueNightMode && colorScheme == .dark {
            return AnyShapeStyle(Color(red: 0.094, green: 0.145, blue: 0.200))
        } else {
            return AnyShapeStyle(colorScheme == .dark ? Color.gray.opacity(0.08) : .white)
        }
    }
}
