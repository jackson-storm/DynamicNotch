//
//  SettingsCardView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsCard<Content: View>: View {
    let title: LocalizedStringKey?
    let spacing: CGFloat
    let padding: CGFloat
    
    private let content: Content
    
    init(
        title: LocalizedStringKey? = nil,
        spacing: CGFloat = 10,
        padding: CGFloat = 6,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.spacing = spacing
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
            .padding(padding)
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
        .groupBoxStyle(SettingsCardGroupBoxStyle(padding: padding))
    }
}

private struct SettingsCardGroupBoxStyle: GroupBoxStyle {
    let padding: CGFloat
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("settings.general.isBlueNightMode") private var isBlueNightMode = false

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            configuration.label
                .padding(.leading, 15)
            configuration.content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(cardFillStyle)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardFillStyle: AnyShapeStyle {
        if isBlueNightMode && colorScheme == .dark {
            return AnyShapeStyle(Color(red: 0.094, green: 0.145, blue: 0.200))
        } else {
            return AnyShapeStyle(colorScheme == .dark ? Color.gray.opacity(0.08) : .white)
        }
    }
}

struct SettingsResetCard: View {
    let action: () -> Void
    
    @State private var showingAlert = false
    
    var body: some View {
        SettingsCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.reset.title")
                        .font(.body)
                    Text("settings.reset.message")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Button(role: .destructive) {
                    showingAlert = true
                } label: {
                    Text("settings.reset.action")
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("settings.reset.title"),
                message: Text("settings.reset.message"),
                primaryButton: .destructive(Text("settings.reset.action")) {
                    action()
                },
                secondaryButton: .cancel()
            )
        }
    }
}
