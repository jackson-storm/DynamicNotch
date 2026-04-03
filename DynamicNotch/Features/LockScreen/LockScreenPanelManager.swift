internal import AppKit
import Combine
import SwiftUI

@MainActor
final class LockScreenPanelAnimator: ObservableObject {
    @Published var isPresented = false
    @Published var disablesTransitionAnimation = false
}

@MainActor
final class LockScreenPanelManager {
    private let nowPlayingViewModel: NowPlayingViewModel
    private let lockScreenManager: LockScreenManager
    private let settingsViewModel: SettingsViewModel
    private let animator = LockScreenPanelAnimator()
    
    private var panelWindow: OverlayPanelWindow?
    private var hostingView: NSHostingView<LockScreenNowPlayingPanelView>?
    private var hasDelegatedWindow = false
    private var appObservers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private var cancellables = Set<AnyCancellable>()
    private var cachedSnapshot: NowPlayingSnapshot?
    private var cachedArtworkImage: NSImage?
    
    init(
        nowPlayingViewModel: NowPlayingViewModel,
        lockScreenManager: LockScreenManager,
        settingsViewModel: SettingsViewModel
    ) {
        self.nowPlayingViewModel = nowPlayingViewModel
        self.lockScreenManager = lockScreenManager
        self.settingsViewModel = settingsViewModel
        
        bindState()
        registerObservers()
    }
    
    func invalidate() {
        appObservers.forEach(NotificationCenter.default.removeObserver)
        appObservers.removeAll()
        
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach(workspaceCenter.removeObserver)
        workspaceObservers.removeAll()
        
        cancellables.removeAll()
        releasePanelResources()
    }
    
    private func bindState() {
        Publishers.CombineLatest4(
            lockScreenManager.$isLocked.removeDuplicates(),
            lockScreenManager.$isPreparingLock.removeDuplicates(),
            nowPlayingViewModel.$snapshot,
            nowPlayingViewModel.$artworkImage
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isLocked, isPreparingLock, liveSnapshot, artworkImage in
            self?.syncPlaybackPresentation(
                isLocked: isLocked,
                isPreparingLock: isPreparingLock,
                liveSnapshot: liveSnapshot,
                artworkImage: artworkImage
            )
        }
        .store(in: &cancellables)
        
        settingsViewModel.application.$displayLocation
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshPosition(animated: false)
            }
            .store(in: &cancellables)
    }
    
    private func registerObservers() {
        appObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshPosition(animated: false)
                }
            }
        )
        
        appObservers.append(
            NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.syncCurrentPresentation()
                }
            }
        )
        
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshPosition(animated: false)
                }
            }
        )
    }
    
    private func syncCurrentPresentation() {
        syncPlaybackPresentation(
            isLocked: lockScreenManager.isLocked,
            isPreparingLock: lockScreenManager.isPreparingLock,
            liveSnapshot: nowPlayingViewModel.snapshot,
            artworkImage: nowPlayingViewModel.artworkImage
        )
    }
    
    private func syncPlaybackPresentation(
        isLocked: Bool,
        isPreparingLock: Bool,
        liveSnapshot: NowPlayingSnapshot?,
        artworkImage: NSImage?
    ) {
        let isShowingLockPresentation = isLocked || isPreparingLock

        if let liveSnapshot {
            cachedSnapshot = liveSnapshot
            cachedArtworkImage = artworkImage
        } else if !isShowingLockPresentation {
            cachedSnapshot = nil
            cachedArtworkImage = nil
        }
        
        let resolvedSnapshot = resolvedSnapshot(
            isShowingLockPresentation: isShowingLockPresentation,
            liveSnapshot: liveSnapshot
        )
        let resolvedArtworkImage = resolvedArtworkImage(
            isShowingLockPresentation: isShowingLockPresentation,
            liveSnapshot: liveSnapshot,
            artworkImage: artworkImage
        )
        
        updatePresentation(
            isShowingLockPresentation: isShowingLockPresentation,
            snapshot: resolvedSnapshot,
            artworkImage: resolvedArtworkImage
        )
    }
    
    private func updatePresentation(
        isShowingLockPresentation: Bool,
        snapshot: NowPlayingSnapshot?,
        artworkImage: NSImage?
    ) {
        guard LockScreenSettings.isMediaPanelEnabled() else {
            hidePanel(animated: true, releaseResources: true)
            return
        }
        
        if isShowingLockPresentation, let snapshot {
            showPanel(snapshot: snapshot, artworkImage: artworkImage, animated: false)
        } else {
            hidePanel(animated: true)
        }
    }
    
    private func showPanel(
        snapshot: NowPlayingSnapshot,
        artworkImage: NSImage?,
        animated: Bool
    ) {
        guard let screen = currentScreen() else { return }
        
        let window = makeWindowIfNeeded()
        let targetFrame = panelFrame(for: screen)
        let rootView = LockScreenNowPlayingPanelView(
            snapshot: snapshot,
            artworkImage: artworkImage,
            nowPlayingViewModel: nowPlayingViewModel,
            lockScreenManager: lockScreenManager,
            animator: animator
        )
        
        if window.frame != targetFrame {
            window.setFrame(targetFrame, display: true)
        }
        
        if let hostingView {
            hostingView.rootView = rootView
            hostingView.frame = NSRect(origin: .zero, size: targetFrame.size)
        } else {
            let hostingView = NSHostingView(rootView: rootView)
            hostingView.frame = NSRect(origin: .zero, size: targetFrame.size)
            hostingView.autoresizingMask = [.width, .height]
            self.hostingView = hostingView
            window.contentView = hostingView
        }
        
        if let hostingView, window.contentView !== hostingView {
            window.contentView = hostingView
        }
        
        if !hasDelegatedWindow {
            SkyLightOperator.shared.delegateWindow(window, to: .lockScreenOverlay)
            hasDelegatedWindow = true
        }
        
        window.orderFrontRegardless()
        
        animator.disablesTransitionAnimation = !animated
        
        guard animated else {
            animator.isPresented = true
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.animator.isPresented = true
        }
    }
    
    private func hidePanel(animated: Bool, releaseResources: Bool = false) {
        animator.disablesTransitionAnimation = !animated
        animator.isPresented = false
        
        guard let window = panelWindow else {
            if releaseResources {
                releasePanelResources()
            }
            return
        }
        let delay = animated ? 0.22 : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak window] in
            guard let self else { return }
            
            let shouldRemainVisible =
            self.lockScreenManager.isShowingLockPresentation &&
            self.resolvedSnapshot(
                isShowingLockPresentation: self.lockScreenManager.isShowingLockPresentation,
                liveSnapshot: self.nowPlayingViewModel.snapshot
            ) != nil &&
            LockScreenSettings.isMediaPanelEnabled()
            
            guard !shouldRemainVisible else { return }
            
            window?.orderOut(nil)

            if releaseResources {
                self.releasePanelResources()
            }
        }
    }

    private func releasePanelResources() {
        cachedSnapshot = nil
        cachedArtworkImage = nil
        animator.isPresented = false

        panelWindow?.orderOut(nil)
        panelWindow?.contentView = nil
        hostingView = nil
        panelWindow = nil
        hasDelegatedWindow = false
    }
    
    private func refreshPosition(animated: Bool) {
        guard let window = panelWindow, window.isVisible, let screen = currentScreen() else {
            return
        }
        
        let targetFrame = panelFrame(for: screen)
        let resolvedSnapshot = resolvedSnapshot(
            isShowingLockPresentation: lockScreenManager.isShowingLockPresentation,
            liveSnapshot: nowPlayingViewModel.snapshot
        )
        let resolvedArtworkImage = resolvedArtworkImage(
            isShowingLockPresentation: lockScreenManager.isShowingLockPresentation,
            liveSnapshot: nowPlayingViewModel.snapshot,
            artworkImage: nowPlayingViewModel.artworkImage
        )
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().setFrame(targetFrame, display: true)
            }
        } else {
            window.setFrame(targetFrame, display: true)
        }
        
        if let resolvedSnapshot, let hostingView {
            hostingView.frame = NSRect(origin: .zero, size: targetFrame.size)
            hostingView.rootView = LockScreenNowPlayingPanelView(
                snapshot: resolvedSnapshot,
                artworkImage: resolvedArtworkImage,
                nowPlayingViewModel: nowPlayingViewModel,
                lockScreenManager: lockScreenManager,
                animator: animator
            )
        }
        
        window.orderFrontRegardless()
    }
    
    private func resolvedSnapshot(
        isShowingLockPresentation: Bool,
        liveSnapshot: NowPlayingSnapshot?
    ) -> NowPlayingSnapshot? {
        liveSnapshot ?? (isShowingLockPresentation ? cachedSnapshot : nil)
    }
    
    private func resolvedArtworkImage(
        isShowingLockPresentation: Bool,
        liveSnapshot: NowPlayingSnapshot?,
        artworkImage: NSImage?
    ) -> NSImage? {
        if liveSnapshot != nil {
            return artworkImage
        }
        
        return isShowingLockPresentation ? cachedArtworkImage : nil
    }
    
    private func makeWindowIfNeeded() -> OverlayPanelWindow {
        if let panelWindow {
            return panelWindow
        }

        let window = OverlayPanelFactory.makePanel(
            frame: NSRect(origin: .zero, size: OverlayWindowLayout.lockScreenCanvasSize),
            level: OverlayWindowLevel.shieldingOverlay
        )

        panelWindow = window
        return window
    }
    
    private func currentScreen() -> NSScreen? {
        NSScreen.preferredLockScreen ??
        NSScreen.preferredNotchScreen(for: settingsViewModel.displayLocation) ??
        NSScreen.main ??
        NSScreen.screens.first
    }
    
    private func panelFrame(for screen: NSScreen) -> NSRect {
        let canvasSize = OverlayWindowLayout.lockScreenCanvasSize
        let size = LockScreenNowPlayingPanelView.panelSize
        let screenFrame = screen.frame
        
        let desiredPanelX = screenFrame.midX - size.width / 2
        let desiredPanelY = screenFrame.midY - size.height - 80
        
        let x = floor(desiredPanelX - (canvasSize.width - size.width) / 2)
        let y = floor(desiredPanelY - (canvasSize.height - size.height) / 2)
        
        return NSRect(origin: CGPoint(x: x, y: y), size: canvasSize)
    }
}
