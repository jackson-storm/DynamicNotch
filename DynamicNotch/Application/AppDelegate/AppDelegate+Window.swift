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

        if isPrimaryWindowHiddenForSystemOverlay {
            hideWindowWorkItem?.cancel()
            hideWindowWorkItem = nil
            window.orderOut(nil)
            return
        }

        let isFullscreen = SkyLightOperator.shared.isFullscreenSpaceActive(on: screen)
        let shouldHideActivities = settingsViewModel.application.isNotchHiddenInFullscreenEnabled && isFullscreen
        let shouldHideDynamicIsland = settingsViewModel.application.isDynamicIslandHiddenInFullscreenEnabled && isFullscreen

        notchViewModel.setActivityPresentationHidden(shouldHideActivities)

        if shouldHideActivities {
            clearNowPlayingPrimaryWindowPresentationState()
        }

        if shouldHideDynamicIsland {
            if notchViewModel.hasDisplayedContent {
                hideWindowWorkItem?.cancel()
                hideWindowWorkItem = nil
                window.orderFrontRegardless()
            } else {
                scheduleDynamicIslandOrderOut()
            }
        } else {
            hideWindowWorkItem?.cancel()
            hideWindowWorkItem = nil
            window.orderFrontRegardless()
        }
    }

    private func scheduleDynamicIslandOrderOut() {
        guard hideWindowWorkItem == nil else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self,
                  let screen = NSScreen.preferredNotchScreen(for: self.settingsViewModel),
                  SkyLightOperator.shared.isFullscreenSpaceActive(on: screen),
                  self.settingsViewModel.application.isDynamicIslandHiddenInFullscreenEnabled,
                  !self.notchViewModel.hasDisplayedContent else {
                return
            }
            self.window?.orderOut(nil)
            self.hideWindowWorkItem = nil
        }
        hideWindowWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private func clearNowPlayingPrimaryWindowPresentationState() {
        nowPlayingViewModel.clearPresentationActivityState()
    }

    func startSystemOverlayVisibilityMonitoring() {
        guard systemOverlayVisibilityMonitor == nil else { return }

        let monitor = SystemOverlayVisibilityMonitor { [weak self] isVisible in
            self?.applySystemOverlayVisibility(isVisible)
        }
        systemOverlayVisibilityMonitor = monitor
        monitor.start()
    }

    func stopSystemOverlayVisibilityMonitoring() {
        systemOverlayVisibilityMonitor?.stop()
        systemOverlayVisibilityMonitor = nil
    }

    private func applySystemOverlayVisibility(_ isVisible: Bool) {
        guard isVisible != isPrimaryWindowHiddenForSystemOverlay else { return }

        isPrimaryWindowHiddenForSystemOverlay = isVisible

        if isVisible {
            animatePrimaryWindowHiddenForSystemOverlay()
        } else {
            animatePrimaryWindowRestoredFromSystemOverlay()
        }
    }

    private func animatePrimaryWindowHiddenForSystemOverlay() {
        guard let window else { return }

        systemOverlayWindowAnimationWorkItem?.cancel()
        hideWindowWorkItem?.cancel()
        hideWindowWorkItem = nil

        let targetFrame = systemOverlayHiddenFrame(from: window.frame)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.10
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
            window.animator().setFrame(targetFrame, display: true)
        }

        let workItem = DispatchWorkItem { [weak self, weak window] in
            guard let self,
                  self.isPrimaryWindowHiddenForSystemOverlay,
                  !self.isPrimaryWindowSuspendedForLock else {
                return
            }

            window?.orderOut(nil)
            window?.alphaValue = 1
            self.systemOverlayWindowAnimationWorkItem = nil
        }
        systemOverlayWindowAnimationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11, execute: workItem)
    }

    private func animatePrimaryWindowRestoredFromSystemOverlay() {
        guard let window else { return }

        systemOverlayWindowAnimationWorkItem?.cancel()
        systemOverlayWindowAnimationWorkItem = nil

        notchViewModel.updateDimensions()

        guard let screen = NSScreen.preferredNotchScreen(for: settingsViewModel) else {
            window.orderOut(nil)
            return
        }

        let targetFrame = OverlayWindowLayout.topAnchoredFrame(
            on: screen,
            size: window.frame.size
        )
        let startFrame = systemOverlayHiddenFrame(from: targetFrame)

        window.collectionBehavior = OverlayPanelFactory.collectionBehavior(
            includesFullscreenAuxiliary: true
        )
        window.alphaValue = 0
        window.setFrame(startFrame, display: true, animate: false)
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.13
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(targetFrame, display: true)
        } completionHandler: { [weak self, weak window] in
            guard let self else { return }

            window?.alphaValue = 1
            if let screen = NSScreen.preferredNotchScreen(for: self.settingsViewModel) {
                self.updatePrimaryWindowPresentation(on: screen)
            }
        }
    }

    private func systemOverlayHiddenFrame(from frame: NSRect) -> NSRect {
        frame.offsetBy(dx: 0, dy: 18)
    }
}
