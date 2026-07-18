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
                    headerTitle: "Language",
                    headerDescription: "Choose the language used by the app interface.",
                    minimumItemWidth: 88,
                    maximumItemWidth: 104,
                    title: { $0.titleKey },
                    accessibilityIdentifier: { "settings.language.option.\($0.rawValue)" }
                ) { language, isSelected in
                    
                    ZStack {
                        if let assetName = language.flagAssetName {
                            Image(assetName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
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
                    
                    Text("Localization only works for settings, the notch remains in English.")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
}
