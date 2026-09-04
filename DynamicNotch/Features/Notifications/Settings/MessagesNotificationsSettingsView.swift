import SwiftUI
internal import AppKit

struct MessagesNotificationsSettingsView: View {
    @ObservedObject var settings: NotificationsSettingsStore
    @ObservedObject var permissionController: SettingsPermissionController
    @State private var isShowingFullDiskAccessAlert = false

    private var notificationDurationRange: ClosedRange<Double> {
        Double(SettingsStoreBase.notificationDurationRange.lowerBound)...Double(SettingsStoreBase.notificationDurationRange.upperBound)
    }

    var body: some View {
        SettingsPageScrollView {
            messagesActivity
            messagesDuration
        }
        .alert(isPresented: $isShowingFullDiskAccessAlert) {
            Alert(
                title: Text("settings.notifications.messages.fullDiskAccess.title"),
                message: Text("settings.notifications.messages.fullDiskAccess.description"),
                primaryButton: .default(
                    Text("settings.permissions.action.openPrivacySettings")
                ) {
                    settings.isMessagesNotificationsPermissionPending = true
                    permissionController.performAction(for: .fullDiskAccess)
                },
                secondaryButton: .cancel {
                    settings.isMessagesNotificationsPermissionPending = false
                }
            )
        }
        .onAppear {
            permissionController.refresh()
        }
    }

    private var messagesActivity: some View {
        SettingsCard(title: "settings.notifications.card.activity") {
            SettingsToggleRow(
                title: "settings.notifications.messages.enabled",
                description: "settings.notifications.messages.enabled.description",
                imageName: "messages",
                color: .clear,
                iconSize: 34,
                isOn: messagesNotificationsBinding,
                accessibilityIdentifier: "settings.notifications.messages.toggle"
            )

            Divider().opacity(0.6)

            SettingsButtonRow(
                title: "settings.notifications.messages.contacts.title",
                description: "settings.notifications.messages.contacts.description",
                systemImage: "person.crop.circle.fill",
                iconSize: 20,
                iconColor: .blue,
                color: .clear,
                buttonTitle: "settings.notifications.messages.contacts.button",
                accessibilityIdentifier: "settings.notifications.messages.contacts",
                action: requestContactsAccess
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

            SettingsButtonRow(
                title: "settings.notifications.messages.systemNotifications.title",
                description: "settings.notifications.messages.systemNotifications.desc",
                systemImage: "exclamationmark.triangle.fill",
                iconSize: 20,
                iconColor: .yellow,
                color: .clear,
                buttonTitle: "settings.notifications.messages.systemNotifications.button",
                accessibilityIdentifier: "settings.notifications.messages.systemNotifications",
                action: openSystemNotificationSettings
            )
        }
    }

    private var messagesDuration: some View {
        SettingsCard(title: "settings.notifications.card.duration") {
            SettingsSliderRow(
                title: "settings.notifications.messages.duration.title",
                description: "settings.notifications.messages.duration.desc",
                range: notificationDurationRange,
                step: 1,
                fractionLength: 0,
                suffix: "s",
                accessibilityIdentifier: "settings.notifications.messages.duration",
                value: Binding(
                    get: { Double(settings.messagesNotificationDuration) },
                    set: { settings.messagesNotificationDuration = Int($0.rounded()) }
                )
            )
            .disabled(!settings.isMessagesNotificationsEnabled)
            .opacity(settings.isMessagesNotificationsEnabled ? 1 : 0.5)
        }
    }

    private var messagesNotificationsBinding: Binding<Bool> {
        Binding(get: { settings.isMessagesNotificationsEnabled }, set: { handleMessagesNotificationsToggle($0) })
    }

    private func handleMessagesNotificationsToggle(_ isEnabled: Bool) {
        guard isEnabled else {
            settings.isMessagesNotificationsPermissionPending = false
            settings.isMessagesNotificationsEnabled = false
            return
        }

        guard permissionController.isFullDiskAccessGranted else {
            isShowingFullDiskAccessAlert = true
            return
        }

        settings.isMessagesNotificationsPermissionPending = false
        settings.isMessagesNotificationsEnabled = true
    }

    private func requestContactsAccess() {
        permissionController.performAction(for: .contacts)
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
