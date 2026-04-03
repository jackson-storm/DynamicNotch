import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
    
    @ObservedObject var settings: ApplicationSettingsStore
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        SettingsPageScrollView {
            SettingsCard(
                title: "settings.language.card.title",
                subtitle: "settings.language.card.subtitle"
            ) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(DynamicNotchLanguage.allCases), id: \.self) { language in
                        languageCard(for: language)
                    }
                }
            }
        }
        .accessibilityIdentifier("settings.language.root")
    }
    
    @ViewBuilder
    private func languageCard(for language: DynamicNotchLanguage) -> some View {
        let isSelected = settings.appLanguage == language
        
        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                settings.appLanguage = language
            }
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    LanguageBadge(language: language, size: 38, fontSize: 12)
                    
                    Spacer(minLength: 8)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white, Color.accentColor)
                    } else {
                        Text(language.codeLabel)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.nativeDisplayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(secondaryLabel(for: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(cardBackground(for: language, isSelected: isSelected))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected ? Color.accentColor.opacity(0.85) : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.22),
                        lineWidth: isSelected ? 1.8 : 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settings.language.option.\(language.rawValue)")
    }
    
    private func cardBackground(for language: DynamicNotchLanguage, isSelected: Bool) -> LinearGradient {
        let colors = language.accentColors
        let baseOpacity = isSelected ? (colorScheme == .dark ? 0.18 : 0.12) : (colorScheme == .dark ? 0.08 : 0.06)
        let neutralOpacity = colorScheme == .dark ? 0.14 : 0.06
        
        return LinearGradient(
            colors: [
                colors[0].opacity(baseOpacity),
                colors[1].opacity(baseOpacity * 0.9),
                Color.primary.opacity(neutralOpacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func secondaryLabel(for language: DynamicNotchLanguage) -> String {
        if language == .system {
            let systemLocale = Locale.autoupdatingCurrent
            return systemLocale.localizedString(forIdentifier: systemLocale.identifier) ?? language.fallbackDisplayName
        }
        
        let localizedName = locale.dn(language.titleKeyString, fallback: language.fallbackDisplayName)
        
        if normalized(localizedName) != normalized(language.nativeDisplayName) {
            return localizedName
        }
        
        if normalized(language.fallbackDisplayName) != normalized(language.nativeDisplayName) {
            return language.fallbackDisplayName
        }
        
        return language.codeLabel
    }
    
    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
    }
}

private struct LanguageBadge: View {
    let language: DynamicNotchLanguage
    let size: CGFloat
    let fontSize: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
            .fill(
                LinearGradient(
                    colors: language.accentColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(language.badgeLabel)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            }
            .shadow(color: language.accentColors[0].opacity(0.18), radius: 10, y: 4)
    }
}
