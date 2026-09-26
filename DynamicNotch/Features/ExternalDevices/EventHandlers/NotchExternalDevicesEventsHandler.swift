//
//  NotchExternalDevicesEventsHandler.swift
//  DynamicNotch
//

import SwiftUI
import Combine
internal import AppKit

@MainActor
final class NotchExternalDevicesEventsHandler {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel
    private let externalDrivesMonitor: ExternalDrivesMonitor

    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel,
        externalDrivesMonitor: ExternalDrivesMonitor
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
        self.externalDrivesMonitor = externalDrivesMonitor

        setupListeners()
    }

    private func setupListeners() {
        externalDrivesMonitor.onDriveEvent = { [weak self] drive in
            self?.handleExternalDriveEvent(drive)
        }
    }

    func handleExternalDriveEvent(_ drive: ExternalDriveModel) {
        guard settingsViewModel.notifications.isExternalDrivesNotificationsEnabled else { return }

        if drive.eventType == .ejected && !settingsViewModel.notifications.isExternalDrivesShowEjectedEnabled {
            return
        }

        let duration = Double(settingsViewModel.notifications.externalDrivesNotificationDuration)
        let volumeURL = drive.volumeURL
        let content = ExternalDriveNotchContent(
            drive: drive,
            onOpen: {
                if let volumeURL {
                    NSWorkspace.shared.open(volumeURL)
                }
            },
            onEject: { [weak externalDrivesMonitor] in
                if let volumeURL {
                    externalDrivesMonitor?.ejectDrive(at: volumeURL)
                }
            }
        )

        notchViewModel.send(.showTemporaryNotification(content, duration: duration))
    }
}

typealias NotchNotificationsEventsHandler = NotchExternalDevicesEventsHandler

