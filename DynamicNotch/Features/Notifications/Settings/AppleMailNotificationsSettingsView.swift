import SwiftUI
internal import AppKit

struct AppleMailNotificationsSettingsView: View {
    @ObservedObject var settings: NotificationsSettingsStore
    @ObservedObject var permissionController: SettingsPermissionController
    @State private var isShowingFullDiskAccessAlert = false

    private var notificationDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.notificationDurationRange.lowerBound)...Double(SettingsStoreBase.notificationDurationRange.upperBound)
    }

    var body: some View {
        SettingsPageScrollView {
            appleMailActivity
            appleMailDuration
        }
        .alert(isPresented: $isShowingFullDiskAccessAlert) {
            Alert(
                title: Text("settings.notifications.appleMail.fullDiskAccess.title"),
                message: Text("settings.notifications.appleMail.fullDiskAccess.description"),
                primaryButton: .default(
                    Text("settings.permissions.action.openPrivacySettings")
                ) {
                    settings.isAppleMailNotificationsPermissionPending = true
                    permissionController.performAction(for: .fullDiskAccess)
                },
                secondaryButton: .cancel {
                    settings.isAppleMailNotificationsPermissionPending = false
                }
            )
        }
    }
    
    private var appleMailActivity: some View {
        SettingsCard(title: "settings.notifications.card.activity") {
            SettingsToggleRow(
                title: "settings.notifications.appleMail.enabled",
                description: "settings.notifications.appleMail.enabled.description",
                imageName: "appleMail",
                color: .clear,
                iconSize: 34,
                isOn: appleMailNotificationsBinding,
                accessibilityIdentifier: "settings.notifications.appleMail.toggle"
            )

            Divider().opacity(0.6)

            SettingsButtonRow(
                title: "settings.notifications.appleMail.systemNotifications.title",
                description: "settings.notifications.appleMail.systemNotifications.desc",
                systemImage: "exclamationmark.triangle.fill",
                iconSize: 20,
                iconColor: .yellow,
                color: .clear,
                buttonTitle: "settings.notifications.appleMail.systemNotifications.button",
                accessibilityIdentifier: "settings.notifications.appleMail.systemNotifications",
                action: openSystemNotificationSettings
            )
        }
    }

    private var appleMailDuration: some View {
        SettingsCard(title: "settings.notifications.card.duration") {
            SettingsSliderRow(
                title: "settings.notifications.appleMail.duration.title",
                description: "settings.notifications.appleMail.duration.desc",
                range: notificationDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.notifications.appleMail.duration",
                value: Binding(
                    get: { Double(settings.appleMailNotificationDuration) },
                    set: { settings.appleMailNotificationDuration = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isAppleMailNotificationsEnabled)
            .opacity(settings.isAppleMailNotificationsEnabled ? 1 : 0.5)
        }
    }

    private var appleMailNotificationsBinding: Binding<Bool> {
        Binding(
            get: {
                settings.isAppleMailNotificationsEnabled
            },
            set: { isEnabled in
                handleMailNotificationsToggle(isEnabled)
            }
        )
    }

    private func handleMailNotificationsToggle(_ isEnabled: Bool) {
        guard isEnabled else {
            settings.isAppleMailNotificationsPermissionPending = false
            settings.isAppleMailNotificationsEnabled = false
            return
        }

        guard permissionController.isFullDiskAccessGranted else {
            isShowingFullDiskAccessAlert = true
            return
        }

        settings.isAppleMailNotificationsPermissionPending = false
        settings.isAppleMailNotificationsEnabled = true
    }

    private func openSystemNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=com.apple.mail"),
           NSWorkspace.shared.open(url) {
            return
        }
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"),
           NSWorkspace.shared.open(url) {
            return
        }
        if let fallbackURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(fallbackURL)
        }
    }
}
