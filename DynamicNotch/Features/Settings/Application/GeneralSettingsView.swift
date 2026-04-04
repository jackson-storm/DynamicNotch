import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            systemCard
            appearanceCard
            displayCard
            languageCard
        }
        .accessibilityIdentifier("settings.general.root")
    }
    
    private var systemCard: some View {
        SettingsCard(
            title: "System",
            subtitle: "Control how Dynamic Notch integrates with macOS."
        ) {
            VStack {
                SettingsToggleRow(
                    title: "Launch at login",
                    description: "Launch Dynamic Notch automatically when you sign in.",
                    systemImage: "power",
                    color: .red,
                    isOn: $applicationSettings.isLaunchAtLoginEnabled,
                    accessibilityIdentifier: "settings.general.launchAtLogin"
                )
                
                Divider()
                
                SettingsToggleRow(
                    title: "Show menu bar icon",
                    description: "Show a menu bar shortcut for quick access to Settings and Quit.",
                    systemImage: "menubar.rectangle",
                    color: .blue,
                    isOn: $applicationSettings.isMenuBarIconVisible,
                    accessibilityIdentifier: "settings.general.menuBarIcon"
                )
                
                Divider()
                
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
    }
    
    private var appearanceCard: some View {
        SettingsCard(
            title: "settings.general.appearance.title",
            subtitle: "settings.general.appearance.subtitle"
        ) {
            CustomPicker(
                selection: $applicationSettings.appearanceMode,
                options: Array(SettingsAppearanceMode.allCases),
                title: { $0.title },
                symbolName: { $0.symbolName }
            )
            .accessibilityIdentifier("settings.general.appearanceMode")
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
}
