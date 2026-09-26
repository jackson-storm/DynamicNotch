import SwiftUI

struct ExternalDevicesSettingsView: View {
    @ObservedObject var settings: ExternalDevicesSettingsStore

    var body: some View {
        ExternalDrivesNotificationsSettingsView(settings: settings)
    }
}

typealias NotificationsSettingsView = ExternalDevicesSettingsView

