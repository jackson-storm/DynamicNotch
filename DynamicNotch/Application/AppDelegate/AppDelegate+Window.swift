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
                wifiViewModel: wifiViewModel,
                vpnViewModel: vpnViewModel,
                downloadViewModel: downloadViewModel,
                focusViewModel: focusViewModel,
                airDropViewModel: airDropViewModel,
                airDropController: airDropController,
                settingsViewModel: settingsViewModel,
                nowPlayingViewModel: nowPlayingViewModel,
                timerViewModel: timerViewModel,
                screenRecordingViewModel: screenRecordingViewModel,
                lockScreenManager: lockScreenManager,
                homePageViewModel: homePageViewModel
            )
        )

        window.contentView = hostingView
        window.collectionBehavior = OverlayPanelFactory.collectionBehavior(
            includesFullscreenAuxiliary: true
        )
        SkyLightOperator.shared.delegateWindow(window, to: .notchSurface)
        updateWindowFrame()
    }

    @objc
    func updateWindowFrame() {
        guard let window else { return }

        notchViewModel.updateDimensions()

        guard let screen = NSScreen.preferredNotchScreen(for: settingsViewModel) else {
            clearNowPlayingPrimaryWindowPresentationState()
            window.orderOut(nil)
            return
        }

        let targetFrame = OverlayWindowLayout.topAnchoredFrame(
            on: screen,
            size: window.frame.size
        )

        window.collectionBehavior = OverlayPanelFactory.collectionBehavior(
            includesFullscreenAuxiliary: true
        )
        window.setFrame(targetFrame, display: true, animate: false)
        updatePrimaryWindowPresentation(on: screen)
    }

    func suspendPrimaryWindowForLock() {
        guard let window, !isPrimaryWindowSuspendedForLock else { return }

        isPrimaryWindowSuspendedForLock = true
        notchViewModel.isLocked = true
        airDropController.resetTargetState()
        clearNowPlayingPrimaryWindowPresentationState()
        notchViewModel.setActivityPresentationHidden(false)
        
        window.level = OverlayWindowLevel.lockScreenNotch
        SkyLightOperator.shared.delegateWindow(window, to: .lockScreenNotchOverlay)
        window.orderFrontRegardless()
    }

    func restorePrimaryWindowForUnlockTransition() {
        guard let window, isPrimaryWindowSuspendedForLock else { return }

        isPrimaryWindowSuspendedForLock = false
        notchViewModel.isLocked = false
        airDropController.resetTargetState()
        
        window.level = OverlayWindowLevel.interactiveNotch
        SkyLightOperator.shared.delegateWindow(window, to: .notchSurface)
        updateWindowFrame()
        reRegisterDragDestination(for: window)
    }

    func reRegisterDragDestination(for window: NSWindow) {
        window.unregisterDraggedTypes()

        func notifyViews(_ view: NSView) {
            if let dragView = view as? DragAndDropView {
                dragView.registerTypes()
            }
            for subview in view.subviews {
                notifyViews(subview)
            }
        }

        if let contentView = window.contentView {
            notifyViews(contentView)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.unregisterDraggedTypes()
            if let contentView = window.contentView {
                notifyViews(contentView)
            }
        }
    }

    private func updatePrimaryWindowPresentation(on screen: NSScreen) {
        guard let window, !isPrimaryWindowSuspendedForLock else { return }

        let shouldHideActivities = shouldHidePrimaryWindowActivitiesInFullscreen(on: screen)
        notchViewModel.setActivityPresentationHidden(shouldHideActivities)

        if shouldHideActivities {
            clearNowPlayingPrimaryWindowPresentationState()
        }

        window.orderFrontRegardless()
    }

    private func shouldHidePrimaryWindowActivitiesInFullscreen(on screen: NSScreen) -> Bool {
        settingsViewModel.application.isNotchHiddenInFullscreenEnabled &&
        SkyLightOperator.shared.isFullscreenSpaceActive(on: screen)
    }

    private func clearNowPlayingPrimaryWindowPresentationState() {
        nowPlayingViewModel.clearPresentationActivityState()
    }
}
