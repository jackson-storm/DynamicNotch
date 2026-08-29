import Foundation
internal import AppKit
import Combine

extension AppDelegate {
    func observeFeatureMonitoringChanges() {
        settingsViewModel.mediaAndFiles.$nowPlayingSourceFilter
            .removeDuplicates()
            .sink { [weak self] sourceFilter in
                self?.nowPlayingViewModel.updateSourceFilter(sourceFilter)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            settingsViewModel.mediaAndFiles.$isNowPlayingLiveActivityEnabled.removeDuplicates(),
            settingsViewModel.lockScreen.$isLockScreenMediaPanelEnabled.removeDuplicates()
        )
        .map { isNowPlayingEnabled, isLockScreenMediaPanelEnabled in
            isNowPlayingEnabled || isLockScreenMediaPanelEnabled
        }
        .removeDuplicates()
        .sink { [weak self] shouldMonitorNowPlaying in
            guard let self else { return }

            if shouldMonitorNowPlaying {
                nowPlayingViewModel.startMonitoring()
            } else {
                nowPlayingViewModel.stopMonitoring()
            }
        }
        .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isDownloadsLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isDownloadsLiveActivityEnabled in
                guard let self else { return }

                if isDownloadsLiveActivityEnabled {
                    downloadViewModel.startMonitoring()
                } else {
                    downloadViewModel.stopMonitoring()
                }
            }
            .store(in: &cancellables)

        settingsViewModel.mediaAndFiles.$isTimerLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isTimerLiveActivityEnabled in
                guard let self else { return }

                if isTimerLiveActivityEnabled {
                    timerViewModel.startMonitoring()
                } else {
                    timerViewModel.stopMonitoring()
                }
            }
            .store(in: &cancellables)

        settingsViewModel.screenRecording.$isScreenRecordingLiveActivityEnabled
            .removeDuplicates()
            .sink { [weak self] isScreenRecordingLiveActivityEnabled in
                guard let self else { return }

                if isScreenRecordingLiveActivityEnabled {
                    screenRecordingViewModel.startMonitoring()
                } else {
                    screenRecordingViewModel.stopMonitoring()
                }
            }
            .store(in: &cancellables)
        
        settingsViewModel.notifications.$isAppleMailNotificationsEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateMailMonitoringState()
            }
            .store(in: &cancellables)

        settingsViewModel.notifications.$isMessagesNotificationsEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateMessagesMonitoringState()
            }
            .store(in: &cancellables)

        settingsViewModel.notifications.$isExternalDrivesNotificationsEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateExternalDrivesMonitoringState()
            }
            .store(in: &cancellables)

        settingsViewModel.notifications.$isExternalDrivesIncludeDiskImagesEnabled
            .removeDuplicates()
            .sink { [weak self] isInclude in
                self?.externalDrivesMonitor.includeDiskImages = isInclude
            }
            .store(in: &cancellables)

        updateExternalDrivesMonitoringState()

        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reconcileMailPermissionState()
                self?.reconcileMessagesPermissionState()
            }
            .store(in: &cancellables)
    }

    func observeDockIconVisibilityChanges() {
        settingsViewModel.application.$isDockIconVisible
            .removeDuplicates()
            .sink { [weak self] isDockIconVisible in
                guard let self, !isRunningUITests else { return }
                applyActivationPolicy(showsDockIcon: isDockIconVisible)
            }
            .store(in: &cancellables)
    }

    func observeDisplayLocationChanges() {
        Publishers.CombineLatest3(
            settingsViewModel.application.$displayLocation.removeDuplicates(),
            settingsViewModel.application.$preferredDisplayUUID.removeDuplicates(),
            settingsViewModel.application.$isDisplayAutoSwitchEnabled.removeDuplicates()
        )
            .removeDuplicates(by: { lhs, rhs in
                lhs.0 == rhs.0 &&
                lhs.1 == rhs.1 &&
                lhs.2 == rhs.2
            })
            .sink { [weak self] _ in
                self?.updateWindowFrame()
            }
            .store(in: &cancellables)
    }

    func observeFullscreenVisibilityChanges() {
        settingsViewModel.application.$isNotchHiddenInFullscreenEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateWindowFrame()
            }
            .store(in: &cancellables)
    }

    func observeHUDConfigurationChanges() {
        Publishers.CombineLatest(
            settingsViewModel.hud.$isVolumeHUDEnabled.removeDuplicates(),
            settingsViewModel.hud.$isBrightnessHUDEnabled.removeDuplicates()
        )
        .sink { [weak self] isVolumeHUDEnabled, isBrightnessHUDEnabled in
            self?.hardwareHUDMonitor.updateConfiguration(
                interceptVolume: isVolumeHUDEnabled,
                interceptBrightness: isBrightnessHUDEnabled
            )
        }
        .store(in: &cancellables)
    }

    func observeLockScreenWindowHandoff() {
        Publishers.CombineLatest3(
            lockScreenManager.$isLocked.removeDuplicates(),
            lockScreenManager.$isPreparingLock.removeDuplicates(),
            lockScreenManager.$isLockIdle.removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isLocked, isPreparingLock, isLockIdle in
            guard let self, !isRunningUITests else { return }

            if isLocked || isPreparingLock {
                suspendPrimaryWindowForLock()
            } else if isPrimaryWindowSuspendedForLock, isLockIdle {
                restorePrimaryWindowForUnlockTransition()
            } else if isLockIdle {
                updateWindowFrame()
            }
        }
        .store(in: &cancellables)
    }

    func observeWorkspaceChanges() {
        let center = NSWorkspace.shared.notificationCenter

        center.addObserver(
            self,
            selector: #selector(handleWorkspaceContextChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(handleWorkspaceContextChange),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    private func updateMailMonitoringState() {
        let isEnabled = settingsViewModel.notifications.isAppleMailNotificationsEnabled
        let hasFullDiskAccess = FullDiskAccessAuthorization.hasPermission()

        if isEnabled && hasFullDiskAccess {
            mailManager.startMonitoring()
        } else {
            mailManager.stopMonitoring()
        }
    }
    
    private func reconcileMailPermissionState() {
        let hasFullDiskAccess = FullDiskAccessAuthorization.hasPermission()
        let settings = settingsViewModel.notifications

        if hasFullDiskAccess {
            if settings.isAppleMailNotificationsPermissionPending {
                settings.isAppleMailNotificationsPermissionPending = false
                settings.isAppleMailNotificationsEnabled = true
            }
        } else {
            settings.isAppleMailNotificationsPermissionPending = false
            settings.isAppleMailNotificationsEnabled = false
        }

        updateMailMonitoringState()
    }

    private func updateMessagesMonitoringState() {
        let isEnabled = settingsViewModel.notifications.isMessagesNotificationsEnabled
        let hasFullDiskAccess = FullDiskAccessAuthorization.hasPermission()

        if isEnabled && hasFullDiskAccess {
            messagesManager.startMonitoring()
        } else {
            messagesManager.stopMonitoring()
        }
    }

    private func reconcileMessagesPermissionState() {
        let hasFullDiskAccess = FullDiskAccessAuthorization.hasPermission()
        let settings = settingsViewModel.notifications

        if hasFullDiskAccess {
            if settings.isMessagesNotificationsPermissionPending {
                settings.isMessagesNotificationsPermissionPending = false
                settings.isMessagesNotificationsEnabled = true
            }
        } else {
            settings.isMessagesNotificationsPermissionPending = false
            settings.isMessagesNotificationsEnabled = false
        }

        updateMessagesMonitoringState()
    }

    func updateExternalDrivesMonitoringState() {
        guard !isRunningUITests else { return }

        let isEnabled = settingsViewModel.notifications.isExternalDrivesNotificationsEnabled
        externalDrivesMonitor.includeDiskImages = settingsViewModel.notifications.isExternalDrivesIncludeDiskImagesEnabled

        if isEnabled {
            externalDrivesMonitor.startMonitoring()
        } else {
            externalDrivesMonitor.stopMonitoring()
        }
    }

    @objc
    func handleWorkspaceContextChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateWindowFrame()
        }
    }
}
