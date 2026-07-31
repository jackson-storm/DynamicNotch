import SwiftUI
internal import AppKit

struct NotificationsSettingsView: View {
    @ObservedObject var settings: NotificationsSettingsStore
    @ObservedObject var notificationCenterViewModel: NotificationCenterViewModel
    let inboxURL: URL

    var body: some View {
        SettingsPageScrollView {
            notificationsActivity
            notificationsActions
        }
    }

    private var notificationsActivity: some View {
        SettingsCard(title: "Notifications activity") {
            SettingsToggleRow(
                title: "Notifications live activity",
                description: "Show the ambient badge on the notch and the Notifications page in the carousel whenever unread items are pending.",
                systemImage: "bell.fill",
                color: .red,
                isOn: $settings.isEnabled,
                accessibilityIdentifier: "settings.notifications.enabled"
            )
        }
    }

    private var notificationsActions: some View {
        SettingsCard(title: "Inbox") {
            Button {
                NSWorkspace.shared.open(inboxURL)
            } label: {
                HStack {
                    Text("Reveal inbox in Finder")
                    Spacer()
                    Image(systemName: "folder")
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().opacity(0.6)

            Button {
                notificationCenterViewModel.clearAll()
            } label: {
                HStack {
                    Text("Clear all notifications")
                        .foregroundStyle(.red)
                    Spacer()
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(notificationCenterViewModel.items.isEmpty)
            .opacity(notificationCenterViewModel.items.isEmpty ? 0.4 : 1)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
