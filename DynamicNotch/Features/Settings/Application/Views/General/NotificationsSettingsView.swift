import SwiftUI

struct NotificationsSettingsView: View {
    @ObservedObject var settings: NotificationsSettingsStore
    @ObservedObject var permissionController: SettingsPermissionController
    @State private var isShowingFullDiskAccessAlert = false

    var body: some View {
        SettingsPageScrollView {
            SettingsCard(title: "settings.notifications.appleMail.title") {
                SettingsToggleRow(
                    title: "settings.notifications.appleMail.enabled",
                    description: "settings.notifications.appleMail.enabled.description",
                    imageName: "appleMail",
                    color: .clear,
                    badgeSize: 40,
                    iconSize: 36,
                    isOn: appleMailNotificationsBinding,
                    accessibilityIdentifier: "settings.notifications.appleMail.toggle"
                )
            }
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
}
