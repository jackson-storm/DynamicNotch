import SwiftUI

struct NotificationsSettingsView: View {
    @ObservedObject var settings: NotificationsSettingsStore
    @ObservedObject var permissionController: SettingsPermissionController

    var body: some View {
        SettingsPageScrollView {
            subPageNavigation
        }
    }

    private var subPageNavigation: some View {
        SettingsCard(spacing: 0, padding: 0) {
            SettingsNavigationRowView(
                title: "settings.notifications.appleMail.title",
                description: "settings.notifications.appleMail.subtitle",
                imageName: "appleMail",
                color: .clear,
                iconSize: 34,
                accessibilityIdentifier: "settings.notifications.appleMail",
                position: .first,
                value: SettingsSubPage.appleMail
            )

            SettingsNavigationRowView(
                title: "settings.notifications.messages.title",
                description: "settings.notifications.messages.subtitle",
                imageName: "messages",
                color: .clear,
                iconSize: 34,
                accessibilityIdentifier: "settings.notifications.messages",
                position: .middle,
                value: SettingsSubPage.messages
            )

            SettingsNavigationRowView(
                title: "settings.notifications.externalDrives.title",
                description: "settings.notifications.externalDrives.subtitle",
                systemImage: "externaldrive.fill",
                iconColor: .white,
                color: .gray,
                accessibilityIdentifier: "settings.notifications.externalDrives",
                position: .last,
                value: SettingsSubPage.externalDrives
            )
        }
    }
}
