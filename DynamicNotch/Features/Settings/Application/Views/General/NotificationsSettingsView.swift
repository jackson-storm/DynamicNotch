//
//  NotificationsSettingsView.swift
//  DynamicNotch
//
//  Created by Igor Volkov on 03.08.2026.
//

import SwiftUI

struct NotificationsSettingsView: View {
    @ObservedObject var settings: NotificationsSettingsStore

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
                    isOn: $settings.isAppleMailNotificationsEnabled,
                    accessibilityIdentifier: "settings.notifications.appleMail.toggle"
                )
            }
        }
    }
}
