import SwiftUI

struct NotificationsSettingsView: View {
    @ObservedObject var settings: NotificationsSettingsStore

    var body: some View {
        ExternalDrivesNotificationsSettingsView(settings: settings)
    }
}

