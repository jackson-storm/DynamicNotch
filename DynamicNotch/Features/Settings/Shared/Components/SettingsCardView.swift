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

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            configuration.label
                .padding(.leading, 15)
            configuration.content
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            isBlueNightMode && colorScheme == .dark
                            ? Color(red: 0.094, green: 0.145, blue: 0.200)
                            : (colorScheme == .dark ? Color.gray.opacity(0.08) : .white)
                        )
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
