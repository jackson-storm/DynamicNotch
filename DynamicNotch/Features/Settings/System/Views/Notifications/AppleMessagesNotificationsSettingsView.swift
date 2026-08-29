import SwiftUI
internal import AppKit

struct AppleMessagesNotificationsSettingsView: View {
    @ObservedObject var settings: NotificationsSettingsStore
    @ObservedObject var permissionController: SettingsPermissionController
    @State private var isShowingFullDiskAccessAlert = false

    private var temporaryActivityDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.temporaryActivityDurationRange.lowerBound)...Double(SettingsStoreBase.temporaryActivityDurationRange.upperBound)
    }

    var body: some View {
        SettingsPageScrollView {
            appleMessagesActivity
            appleMessagesDuration
        }
        .alert(isPresented: $isShowingFullDiskAccessAlert) {
            Alert(
                title: Text("settings.notifications.appleMessages.fullDiskAccess.title"),
                message: Text("settings.notifications.appleMessages.fullDiskAccess.description"),
                primaryButton: .default(
                    Text("settings.permissions.action.openPrivacySettings")
                ) {
                    settings.isAppleMessagesNotificationsPermissionPending = true
                    permissionController.performAction(for: .fullDiskAccess)
                },
                secondaryButton: .cancel {
                    settings.isAppleMessagesNotificationsPermissionPending = false
                }
            )
        }
    }

    private var appleMessagesActivity: some View {
        SettingsCard(title: "settings.notifications.card.activity") {
            SettingsToggleRow(
                title: "settings.notifications.appleMessages.enabled",
                description: "settings.notifications.appleMessages.enabled.description",
                imageName: "appleMessages",
                color: .clear,
                iconSize: 34,
                isOn: appleMessagesNotificationsBinding,
                accessibilityIdentifier: "settings.notifications.appleMessages.toggle"
            )

            Divider().opacity(0.6)

            SettingsButtonRow(
                title: "settings.notifications.appleMessages.systemNotifications.title",
                description: "settings.notifications.appleMessages.systemNotifications.desc",
                systemImage: "exclamationmark.triangle.fill",
                iconSize: 20,
                iconColor: .yellow,
                color: .clear,
                buttonTitle: "settings.notifications.appleMessages.systemNotifications.button",
                accessibilityIdentifier: "settings.notifications.appleMessages.systemNotifications",
                action: openSystemNotificationSettings
            )
        }
    }

    private var appleMessagesDuration: some View {
        SettingsCard(title: "settings.notifications.card.duration") {
            SettingsSliderRow(
                title: "settings.notifications.appleMessages.duration.title",
                description: "settings.notifications.appleMessages.duration.desc",
                range: temporaryActivityDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.notifications.appleMessages.duration",
                value: Binding(
                    get: { Double(settings.appleMessagesNotificationDuration) },
                    set: { settings.appleMessagesNotificationDuration = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isAppleMessagesNotificationsEnabled)
            .opacity(settings.isAppleMessagesNotificationsEnabled ? 1 : 0.5)
        }
    }

    private var appleMessagesNotificationsBinding: Binding<Bool> {
        Binding(
            get: {
                settings.isAppleMessagesNotificationsEnabled
            },
            set: { isEnabled in
                handleMessagesNotificationsToggle(isEnabled)
            }
        )
    }

    private func handleMessagesNotificationsToggle(_ isEnabled: Bool) {
        guard isEnabled else {
            settings.isAppleMessagesNotificationsPermissionPending = false
            settings.isAppleMessagesNotificationsEnabled = false
            return
        }

        guard permissionController.isFullDiskAccessGranted else {
            isShowingFullDiskAccessAlert = true
            return
        }

        settings.isAppleMessagesNotificationsPermissionPending = false
        settings.isAppleMessagesNotificationsEnabled = true
    }

    private func openSystemNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=com.apple.MobileSMS"),
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
