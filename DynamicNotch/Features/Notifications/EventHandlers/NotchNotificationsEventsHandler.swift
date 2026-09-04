//
//  NotchNotificationsEventsHandler.swift
//  DynamicNotch
//

import SwiftUI
import Combine
internal import AppKit

@MainActor
final class NotchNotificationsEventsHandler {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel
    private let mailManager: MailManager
    private let messagesManager: MessagesManager
    private let externalDrivesMonitor: ExternalDrivesMonitor
    
    private var recentNotifications: [AppNotificationItem] = []
    private var isMessagesAudioPlaying = false
    private var cancellables = Set<AnyCancellable>()
    
    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel,
        mailManager: MailManager,
        messagesManager: MessagesManager,
        externalDrivesMonitor: ExternalDrivesMonitor
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
        self.mailManager = mailManager
        self.messagesManager = messagesManager
        self.externalDrivesMonitor = externalDrivesMonitor
        
        setupListeners()
        observeMessagesPresentation()
    }
    
    private func setupListeners() {
        mailManager.onMessageReceived = { [weak self] message in
            self?.handleMailMessage(message)
        }
        
        messagesManager.onMessageReceived = { [weak self] message in
            self?.handleMessagesMessage(message)
        }
        
        externalDrivesMonitor.onDriveEvent = { [weak self] drive in
            self?.handleExternalDriveEvent(drive)
        }
    }
    
    func handleMailMessage(_ message: MailMessage) {
        guard settingsViewModel.notifications.isAppleMailNotificationsEnabled else { return }

        recentNotifications.removeAll { $0.id == "mail-\(message.rowID)" }
        recentNotifications.append(.mail(message))
        recentNotifications = Array(recentNotifications.suffix(2))

        showNotificationsNotification(duration: Double(settingsViewModel.notifications.appleMailNotificationDuration))
    }

    func handleMessagesMessage(_ message: MessagesMessage) {
        guard settingsViewModel.notifications.isMessagesNotificationsEnabled else { return }

        recentNotifications.removeAll { $0.id == "msg-\(message.id)" }
        recentNotifications.append(.message(message))
        recentNotifications = Array(recentNotifications.suffix(2))

        showNotificationsNotification(duration: Double(settingsViewModel.notifications.messagesNotificationDuration))
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

    private func handleMessagesAudioPlaybackStateChanged(_ isPlaying: Bool) {
        let isShowingMessages = notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Notifications.messages.id

        guard isShowingMessages else {
            isMessagesAudioPlaying = false
            return
        }

        guard isMessagesAudioPlaying != isPlaying else { return }

        isMessagesAudioPlaying = isPlaying
        showNotificationsNotification()
    }

    private func showNotificationsNotification(duration: Double? = nil) {
        guard !recentNotifications.isEmpty else { return }

        let baseDuration = duration ?? Double(settingsViewModel.notifications.messagesNotificationDuration)
        let effectiveDuration: TimeInterval = isMessagesAudioPlaying
            ? .infinity
            : settingsViewModel.scaledTemporaryActivityDuration(baseDuration)

        let content = NotificationsNotchContent(
            items: recentNotifications,
            onAudioPlaybackStateChanged: { [weak self] isPlaying in
                Task { @MainActor [weak self] in
                    self?.handleMessagesAudioPlaybackStateChanged(isPlaying)
                }
            },
            onOpenMessage: { [weak self] selectedMessage in
                guard let self else { return }

                messagesManager.open(selectedMessage)
                notchViewModel.hideTemporaryNotification()
            },
            onOpenMail: { [weak self] selectedMail in
                guard let self else { return }

                mailManager.open(selectedMail)
                notchViewModel.hideTemporaryNotification()
            }
        )

        notchViewModel.send(.showTemporaryNotification(content, duration: effectiveDuration))
    }

    private func observeMessagesPresentation() {
        notchViewModel.$notchModel
            .map { model in
                model.temporaryNotificationContent?.id == NotchContentRegistry.Notifications.messages.id
            }
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] isShowingMessages in
                guard let self, !isShowingMessages else { return }

                recentNotifications.removeAll()
            }
            .store(in: &cancellables)
    }
}
