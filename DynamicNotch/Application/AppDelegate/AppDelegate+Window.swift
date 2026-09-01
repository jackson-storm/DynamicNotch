import SwiftUI
import UniformTypeIdentifiers

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
                notchEventCoordinator: notchEventCoordinator,
                notchViewModel: notchViewModel,
                airDropViewModel: airDropViewModel,
                airDropController: airDropController,
                settingsViewModel: settingsViewModel
            )
        )

        window.contentView = hostingView
        window.collectionBehavior = OverlayPanelFactory.collectionBehavior(
            includesFullscreenAuxiliary: true
        )
        SkyLightOperator.shared.delegateWindow(window, to: .notchSurface)
        updateWindowFrame()
        reRegisterDragDestination(for: window)
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
        
        window.orderOut(nil)
    }

    func restorePrimaryWindowForUnlockTransition() {
        guard let window, isPrimaryWindowSuspendedForLock else { return }

        isPrimaryWindowSuspendedForLock = false
        notchViewModel.isLocked = false
        airDropController.resetTargetState()
        
        updateWindowFrame()
        reRegisterDragDestination(for: window)
    }

    func reRegisterDragDestination(for window: NSWindow) {
        let dragTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            .URL,
            NSPasteboard.PasteboardType(UTType.data.identifier)
        ]

        func notifyViews(_ view: NSView) {
            if let dragView = view as? DragAndDropView {
                dragView.registerTypes()
            }
            for subview in view.subviews {
                notifyViews(subview)
            }
        }

        func performRegistration() {
            window.registerForDraggedTypes(dragTypes)
            if let contentView = window.contentView {
                notifyViews(contentView)
            }
        }

        // Immediate pass
        performRegistration()

        // Staggered passes to ensure WindowServer space transition has finished
        for delay in [0.2, 0.6, 1.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                performRegistration()
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
