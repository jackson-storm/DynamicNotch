import SwiftUI
internal import AppKit

struct NotificationsSettingsView: View {
    @ObservedObject var settings: NotificationsSettingsStore
    @ObservedObject var notificationCenterViewModel: NotificationCenterViewModel
    let inboxURL: URL

    @State private var isInstallingCLI = false
    @State private var cliInstallMessage: LocalizedStringKey?

    var body: some View {
        SettingsPageScrollView {
            notificationsActivity
            notificationsActions
            commandLineTool
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

    private var commandLineTool: some View {
        SettingsCard(title: "Command-line tool") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Install the dynamicnotch command so scripts, cron jobs and Shortcuts can push notifications from any terminal.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    installCLI()
                } label: {
                    HStack {
                        Text("Install CLI tool")
                        Spacer()
                        if isInstallingCLI {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "terminal")
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .disabled(isInstallingCLI)

                if let cliInstallMessage {
                    Text(cliInstallMessage)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    /// Runs the (blocking) installer off the main thread — the privileged path waits on an admin
    /// dialog — then maps the outcome to a localized result line back on the main actor.
    private func installCLI() {
        isInstallingCLI = true
        cliInstallMessage = nil
        Task {
            let outcome = await Task.detached(priority: .userInitiated) {
                CLIToolInstaller.install()
            }.value
            isInstallingCLI = false
            cliInstallMessage = Self.message(for: outcome)
        }
    }

    private static func message(for outcome: CLIToolInstaller.Outcome) -> LocalizedStringKey {
        switch outcome {
        case .installed, .installedWithPrivileges:
            "Installed. dynamicnotch is now available on your PATH."
        case .permissionDenied:
            "Installation was cancelled. Administrator permission is required."
        case .binaryMissing:
            "The command-line tool is missing from the app bundle."
        case .failed:
            "Installation failed. Check that /usr/local/bin is writable."
        }
    }
}
