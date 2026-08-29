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
                title: "settings.notifications.appleMessages.title",
                description: "settings.notifications.appleMessages.subtitle",
                imageName: "appleMessages",
                color: .clear,
                iconSize: 34,
                accessibilityIdentifier: "settings.notifications.appleMessages",
                position: .last,
                value: SettingsSubPage.appleMessages
            )
        }
    }
}
