//
//  LanguageSettingsView.swift
//  DynamicNotch
//
//  Created by Евгений Петрукович on 7/13/26.
//

import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    var isEmbedded: Bool = false
    
    @State private var selectedTarget: LanguageTarget = .settings
    
    enum LanguageTarget: String, CaseIterable, Identifiable {
        case settings
        case notch
        
        var id: String { rawValue }
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .settings:
                return "settings.language.target.settings"
            case .notch:
                return "settings.language.target.notch"
            }
        }
    }
    
    var body: some View {
        Group {
            if isEmbedded {
                content
            } else {
                content
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Picker("", selection: $selectedTarget.animation(.easeInOut(duration: 0.15))) {
                                ForEach(LanguageTarget.allCases) { target in
                                    Text(target.titleKey).tag(target)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
            }
        }
    }
    
    private var content: some View {
        SettingsPageScrollView {
            systemLanguageCard
            
            switch selectedTarget {
            case .settings:
                settingsLanguageListCard
            case .notch:
                notchLanguageListCard
            }

            SettingsResetCard(targetName: localized("settings.section.language.title", fallback: "Language")) {
                applicationSettings.resetLanguage()
            }
        }
    }

    private func localized(_ key: String, fallback: String? = nil) -> String {
        applicationSettings.appLanguage.locale.dn(key, fallback: fallback)
    }
    
    private var systemLanguageCard: some View {
        SettingsCard {
            if isEmbedded {
                Picker("", selection: $selectedTarget.animation(.easeInOut(duration: 0.15))) {
                    ForEach(LanguageTarget.allCases) { target in
                        Text(target.titleKey).tag(target)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                
                Divider()
                    .opacity(0.6)
            }
            
            SettingsToggleRow(
                title: "settings.language.option.system",
                description: currentSystemDescription,
                systemImage: "globe",
                color: .blue,
                isOn: systemToggleBinding,
                accessibilityIdentifier: "settings.language.systemToggle"
            )
        }
    }
    
    private var currentSystemDescription: LocalizedStringKey {
        switch selectedTarget {
        case .settings:
            return "settings.language.header.desc"
        case .notch:
            return "settings.language.notch.desc"
        }
    }
    
    private var systemToggleBinding: Binding<Bool> {
        Binding(
            get: {
                switch selectedTarget {
                case .settings:
                    return applicationSettings.appLanguage == .system
                case .notch:
                    return applicationSettings.notchLanguage == .system
                }
            },
            set: { isSystem in
                withAnimation(.easeInOut(duration: 0.15)) {
                    switch selectedTarget {
                    case .settings:
                        if isSystem {
                            applicationSettings.appLanguage = .system
                        } else if applicationSettings.appLanguage == .system {
                            applicationSettings.appLanguage = .english
                        }
                    case .notch:
                        if isSystem {
                            applicationSettings.notchLanguage = .system
                        } else if applicationSettings.notchLanguage == .system {
                            applicationSettings.notchLanguage = .english
                        }
                    }
                }
            }
        )
    }
    
    private var settingsLanguageListCard: some View {
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
    
    private var notchLanguageListCard: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsSearchableListView(
                items: DynamicNotchLanguage.notchLanguages,
                selection: $applicationSettings.notchLanguage,
                title: { $0.titleKey },
                subtitle: { $0.fallbackDisplayName },
                matchesQuery: { language, query in
                    language.fallbackDisplayName.lowercased().contains(query) ||
                    language.nativeDisplayName.lowercased().contains(query) ||
                    language.rawValue.lowercased().contains(query) ||
                    L10n.string(language.titleKeyString, language: applicationSettings.appLanguage).lowercased().contains(query)
                },
                accessibilityIdentifier: { "settings.language.notch.option.\($0.rawValue)" }
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
