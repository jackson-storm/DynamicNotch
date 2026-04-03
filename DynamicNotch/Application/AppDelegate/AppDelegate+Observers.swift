import Foundation
internal import AppKit
import Combine

extension AppDelegate {
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
        settingsViewModel.application.$displayLocation
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
            } else if isPrimaryWindowSuspendedForLock {
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

    @objc
    func handleWorkspaceContextChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateWindowFrame()
        }
    }
}
