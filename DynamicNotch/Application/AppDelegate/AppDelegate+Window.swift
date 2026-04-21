import SwiftUI

extension AppDelegate {
    func createNotchWindow() {
        guard let screen =
            NSScreen.preferredNotchScreen(for: settingsViewModel) ??
            NSScreen.preferredNotchScreen(for: settingsViewModel.application) ??
            NSScreen.preferredNotchScreen(for: .main) ??
            NSScreen.screens.first
        else {
            return
        }

        let frame = OverlayWindowLayout.topAnchoredFrame(
            on: screen,
            size: OverlayWindowLayout.appCanvasSize
        )

        window = OverlayPanelFactory.makePanel(
            frame: frame,
            level: OverlayWindowLevel.interactiveNotch
        )

        let hostingView = NotchHostingView(
            rootView: NotchView(
                notchViewModel: notchViewModel,
                notchEventCoordinator: notchEventCoordinator,
                powerViewModel: powerViewModel,
                bluetoothViewModel: bluetoothViewModel,
                networkViewModel: networkViewModel,
                downloadViewModel: downloadViewModel,
                focusViewModel: focusViewModel,
                airDropViewModel: airDropViewModel,
                airDropController: airDropController,
                settingsViewModel: settingsViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                timerViewModel: timerViewModel,
                lockScreenManager: lockScreenManager
            )
        )

        window.contentView = hostingView
        window.collectionBehavior = OverlayPanelFactory.collectionBehavior(
            includesFullscreenAuxiliary: !settingsViewModel.application.isNotchHiddenInFullscreenEnabled
        )
        SkyLightOperator.shared.delegateWindow(window, to: .notchSurface)
        updateWindowFrame()
    }

    @objc
    func updateWindowFrame() {
        guard let window else { return }

        notchViewModel.updateDimensions()

        guard let screen = NSScreen.preferredNotchScreen(for: settingsViewModel) else {
            window.orderOut(nil)
            return
        }

        let targetFrame = OverlayWindowLayout.topAnchoredFrame(
            on: screen,
            size: window.frame.size
        )

        window.collectionBehavior = OverlayPanelFactory.collectionBehavior(
            includesFullscreenAuxiliary: !settingsViewModel.application.isNotchHiddenInFullscreenEnabled
        )
        window.setFrame(targetFrame, display: true, animate: false)
        updatePrimaryWindowVisibility(on: screen)
    }

    func suspendPrimaryWindowForLock() {
        guard let window, !isPrimaryWindowSuspendedForLock else { return }

        isPrimaryWindowSuspendedForLock = true
        window.orderOut(nil)
    }

    func restorePrimaryWindowForUnlockTransition() {
        guard isPrimaryWindowSuspendedForLock else { return }

        isPrimaryWindowSuspendedForLock = false
        updateWindowFrame()
    }

    private func updatePrimaryWindowVisibility(on screen: NSScreen) {
        guard let window, !isPrimaryWindowSuspendedForLock else { return }

        if shouldHidePrimaryWindowInFullscreen(on: screen) {
            window.orderOut(nil)
        } else {
            window.orderFrontRegardless()
        }
    }

    private func shouldHidePrimaryWindowInFullscreen(on screen: NSScreen) -> Bool {
        settingsViewModel.application.isNotchHiddenInFullscreenEnabled &&
        SkyLightOperator.shared.isFullscreenSpaceActive(on: screen)
    }
}
