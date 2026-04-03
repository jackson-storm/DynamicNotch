import SwiftUI

struct LanguagePicker: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selection: DynamicNotchLanguage

    var body: some View {
        AdaptiveCustomPicker(
            selection: $selection,
            options: Array(DynamicNotchLanguage.allCases),
            minimumItemWidth: 88,
            maximumItemWidth: 104,
            title: { $0.titleKey },
            accessibilityIdentifier: { "settings.language.option.\($0.rawValue)" }
        ) { language, isSelected in
            languagePreview(for: language, isSelected: isSelected)
        }
    }

    @ViewBuilder
    private func languagePreview(for language: DynamicNotchLanguage, isSelected: Bool) -> some View {
        ZStack {
            if let assetName = language.flagAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .padding(.vertical, 6)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
