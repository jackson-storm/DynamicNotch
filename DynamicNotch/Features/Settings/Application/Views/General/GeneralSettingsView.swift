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
            firstCard
            secondCard
            thirdCard
            fourthCard
        }
        .accessibilityIdentifier("settings.general.root")
    }
    
    private var firstCard: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsNavigationRowView(
                title: "settings.general.system.title",
                description: "settings.general.system.subtitle",
                systemImage: "macbook.gen2",
                color: .gray,
                accessibilityIdentifier: "settings.general.system",
                position: .single,
                value: SettingsSubPage.system
            )
        }
    }
    
    private var secondCard: some View {
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
    
    private var thirdCard: some View {
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
                title: "settings.general.support.title",
                description: "settings.general.support.subtitle",
                systemImage: "heart.fill",
                color: .red,
                accessibilityIdentifier: "settings.general.support",
                position: .last,
                value: SettingsSubPage.support
            )
        }
    }
    
    private var fourthCard: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsNavigationRowView(
                title: "settings.section.about.title",
                description: "settings.section.about.subtitle",
                systemImage: "info.circle.fill",
                color: .gray,
                accessibilityIdentifier: "settings.general.about",
                position: .single,
                value: SettingsSubPage.about
            )
        }
    }
}
