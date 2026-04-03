import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    
    var body: some View {
        SettingsPageScrollView {
            systemCard
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
            LanguagePicker(selection: $applicationSettings.appLanguage)
                .accessibilityIdentifier("settings.language.card")
        }
    }
}
