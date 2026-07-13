import SwiftUI
internal import AppKit

struct GeneralSettingsView: View {
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    @ObservedObject var permissionController: SettingsPermissionController
    
    init(applicationSettings: ApplicationSettingsStore, permissionController: SettingsPermissionController) {
        self._applicationSettings = ObservedObject(wrappedValue: applicationSettings)
        self._permissionController = ObservedObject(wrappedValue: permissionController)
    }
    
    var body: some View {
        SettingsPageScrollView {
            systemCard
            firstCard
            secondCard
        }
        .accessibilityIdentifier("settings.general.root")
    }
    
    private var systemCard: some View {
        SettingsCard(title: "System") {
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
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            SettingsToggleRow(
                title: "Show Dock icon",
                description: "Keep the app visible in the Dock for faster switching and window access.",
                systemImage: "dock.rectangle",
                color: .orange,
                isOn: $applicationSettings.isDockIconVisible,
                accessibilityIdentifier: "settings.general.dockIcon"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 14) {
                SettingsToggleRow(
                    title: "Show menu bar icon",
                    description: "Show a menu bar shortcut for quick access to Settings and Quit.",
                    systemImage: "menubar.rectangle",
                    color: .blue,
                    isOn: $applicationSettings.isMenuBarIconVisible,
                    accessibilityIdentifier: "settings.general.menuBarIcon"
                )
                if !applicationSettings.isMenuBarIconVisible {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.yellow)
                        
                        Text("You can access the menu by right-clicking on the notch area.")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
    }
    
    private var firstCard: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsNavigationRowView(
                title: "settings.general.appearance.title",
                description: "settings.general.appearance.subtitle",
                systemImage: "paintbrush.fill",
                color: .teal.opacity(0.9),
                accessibilityIdentifier: "settings.general.appearance",
                position: .first,
                value: SettingsSubPage.appearance
            )
            
            SettingsNavigationRowView(
                title: "settings.general.display.title",
                description: "Configure the display where the notch will be shown.",
                systemImage: "display.2",
                color: .black,
                accessibilityIdentifier: "settings.general.display",
                position: .middle,
                value: SettingsSubPage.display
            )
            
            SettingsNavigationRowView(
                title: "settings.section.language.title",
                description: "settings.section.language.subtitle",
                systemImage: "globe",
                color: .blue,
                accessibilityIdentifier: "settings.general.language",
                position: .last,
                value: SettingsSubPage.language
            )
        }
    }
    
    private var secondCard: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsNavigationRowView(
                title: "Software Update",
                description: "Check for updates and manage update preferences.",
                systemImage: "gear.badge",
                color: .gray,
                accessibilityIdentifier: "settings.general.softwareUpdate",
                position: .first,
                value: SettingsSubPage.softwareUpdate
            )
            
            SettingsNavigationRowView(
                title: "settings.section.permissions.title",
                description: "settings.section.permissions.subtitle",
                systemImage: "checkmark.seal.fill",
                color: .green.opacity(0.9),
                accessibilityIdentifier: "settings.general.permissions",
                position: .middle,
                value: SettingsSubPage.permissions
            )
            
            SettingsNavigationRowView(
                title: "settings.section.about.title",
                description: "settings.section.about.subtitle",
                systemImage: "info.circle.fill",
                color: .gray,
                accessibilityIdentifier: "settings.general.about",
                position: .last,
                value: SettingsSubPage.about
            )
        }
    }
}
