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
            languageCard
        }
    }
    
    private var languageCard: some View {
        SettingsCard() {
            VStack(alignment: .leading, spacing: 12) {
                AdaptiveCustomPicker(
                    selection: $applicationSettings.appLanguage,
                    options: Array(DynamicNotchLanguage.allCases),
                    headerTitle: "settings.language.header.title",
                    headerDescription: "settings.language.header.desc",
                    minimumItemWidth: 88,
                    maximumItemWidth: 104,
                    title: { $0.titleKey },
                    accessibilityIdentifier: { "settings.language.option.\($0.rawValue)" }
                ) { language, isSelected in
                    
                    ZStack {
                        if let assetName = language.flagAssetName {
                            Image(assetName)
                                .resizable()
                                .interpolation(.high)
                                .antialiased(true)
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous), style: FillStyle(antialiased: true))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                                }
                                .frame(width: 54, height: 54)
                            
                        } else {
                            Image(systemName: "globe")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(width: 54, height: 54)
                }
                .accessibilityIdentifier("settings.language.card")
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.yellow)
                    
                    Text(LocalizedStringKey("settings.language.notice"))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
}
