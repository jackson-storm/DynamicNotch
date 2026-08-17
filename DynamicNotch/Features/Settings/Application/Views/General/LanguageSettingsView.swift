//
//  LanguageSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/13/26.
//

import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            systemLanguageCard
            languageListCard
        }
    }
    
    private var systemLanguageCard: some View {
        SettingsCard {
            SettingsToggleRow(
                title: "settings.language.option.system",
                description: "settings.language.header.desc",
                systemImage: "globe",
                color: .blue,
                isOn: Binding(
                    get: { applicationSettings.appLanguage == .system },
                    set: { isSystem in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if isSystem {
                                applicationSettings.appLanguage = .system
                            } else if applicationSettings.appLanguage == .system {
                                applicationSettings.appLanguage = .english
                            }
                        }
                    }
                ),
                accessibilityIdentifier: "settings.language.systemToggle"
            )
            
            Divider()
                .opacity(0.6)
            
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.yellow)
                
                Text(LocalizedStringKey("settings.language.notice"))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var languageListCard: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsSearchableListView(
                items: availableLanguages,
                selection: $applicationSettings.appLanguage,
                title: { $0.titleKey },
                subtitle: { $0.fallbackDisplayName },
                matchesQuery: { language, query in
                    language.fallbackDisplayName.lowercased().contains(query) ||
                    language.nativeDisplayName.lowercased().contains(query) ||
                    language.rawValue.lowercased().contains(query) ||
                    L10n.string(language.titleKeyString, language: applicationSettings.appLanguage).lowercased().contains(query)
                },
                accessibilityIdentifier: { "settings.language.option.\($0.rawValue)" }
            ) { language in
                flagView(for: language)
            }
        }
    }
    
    private var availableLanguages: [DynamicNotchLanguage] {
        DynamicNotchLanguage.allCases.filter { $0 != .system }
    }
    
    @ViewBuilder
    private func flagView(for language: DynamicNotchLanguage) -> some View {
        ZStack {
            if let assetName = language.flagAssetName {
                Image(assetName)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                    }
            }
        }
        .frame(width: 28, height: 20)
    }
}
