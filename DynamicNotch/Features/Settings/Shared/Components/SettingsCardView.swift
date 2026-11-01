//
//  SettingsCardView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 4/4/26.
//

import SwiftUI

struct SettingsCard<Content: View>: View {
    let title: LocalizedStringKey?
    let titleText: Text?
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
        self.titleText = title.map { Text($0) }
        self.spacing = spacing
        self.padding = padding
        self.content = content()
    }

    init(
        verbatimTitle: String,
        spacing: CGFloat = 10,
        padding: CGFloat = 6,
        @ViewBuilder content: () -> Content
    ) {
        self.title = nil
        self.titleText = Text(verbatim: verbatimTitle)
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
            if let titleText {
                VStack(alignment: .leading) {
                    titleText
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

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            configuration.label
                .padding(.leading, 15)
            configuration.content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(cardFillStyle)
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .strokeBorder(cardStrokeColor, lineWidth: 0.5)
                        }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardFillStyle: AnyShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color.white.opacity(0.05))
        } else {
            return AnyShapeStyle(Color.white.opacity(0.5))
        }
    }

    private var cardStrokeColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.04)
        } else {
            return Color.black.opacity(0.06)
        }
    }
}

struct SettingsResetCard: View {
    let targetName: String
    let action: () -> Void
    
    @State private var showingAlert = false
    @Environment(\.locale) private var locale
    
    var formattedTitle: String {
        locale.dnFormat("settings.reset.title", fallback: "Reset %@ settings?", targetName)
    }
    
    var body: some View {
        SettingsCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedTitle)
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
                title: Text(formattedTitle),
                message: Text("settings.reset.message"),
                primaryButton: .destructive(Text("settings.reset.action")) {
                    action()
                },
                secondaryButton: .cancel()
            )
        }
    }
}
