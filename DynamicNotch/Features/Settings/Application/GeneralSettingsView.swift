import SwiftUI

struct GeneralSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            systemCard
            displayCard
            appearanceCard
            languageCard
        }
        .accessibilityIdentifier("settings.general.root")
    }
    
    private var systemCard: some View {
        SettingsCard(
            title: "System",
            subtitle: "Control how Dynamic Notch integrates with macOS."
        ) {
            SettingsToggleRow(
                title: "Launch at login",
                description: "Launch Dynamic Notch automatically when you sign in.",
                systemImage: "power",
                color: .red,
                isOn: $applicationSettings.isLaunchAtLoginEnabled,
                accessibilityIdentifier: "settings.general.launchAtLogin"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Show menu bar icon",
                description: "Show a menu bar shortcut for quick access to Settings and Quit.",
                systemImage: "menubar.rectangle",
                color: .blue,
                isOn: $applicationSettings.isMenuBarIconVisible,
                accessibilityIdentifier: "settings.general.menuBarIcon"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Show Dock icon",
                description: "Keep the app visible in the Dock for faster switching and window access.",
                systemImage: "dock.rectangle",
                color: .orange,
                isOn: $applicationSettings.isDockIconVisible,
                accessibilityIdentifier: "settings.general.dockIcon"
            )
        }
    }
    
    private var displayCard: some View {
        SettingsCard(
            title: "Display",
            subtitle: "Choose which display should host the notch overlay."
        ) {
            CustomPicker(
                selection: $applicationSettings.displayLocation,
                options: Array(NotchDisplayLocation.allCases),
                title: { $0.title },
                symbolName: { $0.symbolName }
            )
            .accessibilityIdentifier("settings.general.displayLocation")
        }
    }
    
    private var appearanceCard: some View {
        SettingsCard(
            title: "settings.general.appearance.title",
            subtitle: "settings.general.appearance.subtitle"
        ) {
            themePickerSection
            Divider().opacity(0.6)
            tintPickerSection
        }
    }
    
    private var languageCard: some View {
        SettingsCard(
            title: "settings.language.card.title",
            subtitle: "settings.language.card.subtitle"
        ) {
            AdaptiveCustomPicker(
                selection: $applicationSettings.appLanguage,
                options: Array(DynamicNotchLanguage.allCases),
                minimumItemWidth: 88,
                maximumItemWidth: 104,
                title: { $0.titleKey },
                accessibilityIdentifier: { "settings.language.option.\($0.rawValue)" }
            ) { language, isSelected in
                languagePreview(for: language, isSelected: isSelected)
            }
            .accessibilityIdentifier("settings.language.card")
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
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: 44, height: 34)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
    
    private var themePickerSection: some View {
        CustomPicker(
            selection: $applicationSettings.appearanceMode,
            options: Array(SettingsAppearanceMode.allCases),
            title: { $0.title },
            headerTitle: "Theme",
            headerDescription: "Choose the interface appearance used by the app.",
            symbolName: { $0.symbolName }
        )
        .accessibilityIdentifier("settings.general.appearanceMode")
    }
    
    private var tintPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tint")
                    
                    Text("Choose the accent color used across the app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 12)
                
                Text(applicationSettings.appTint.title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 30, maximum: 30), spacing: 12)],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(AppTint.allCases) { tint in
                    Button {
                        applicationSettings.appTint = tint
                    } label: {
                        tintSwatch(for: tint)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.general.tint.\(tint.rawValue)")
                    .accessibilityLabel(Text("\(tint.title) tint"))
                }
            }
        }
    }
    
    @ViewBuilder
    private func tintSwatch(for tint: AppTint) -> some View {
        let isSelected = applicationSettings.appTint == tint
        
        Circle()
            .fill(tint.color.gradient)
            .frame(width: 30, height: 30)
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                }
            }
            .padding(4)
            .overlay {
                Circle()
                    .strokeBorder(
                        isSelected ?
                        Color.primary.opacity(colorScheme == .dark ? 0.8 : 0.25) :
                            Color.clear,
                        lineWidth: 1.5
                    )
            }
            .scaleEffect(isSelected ? 1 : 0.94)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: isSelected)
    }
}
