import AppKit
import Combine
import SwiftUI

@MainActor
final class LockScreenPanelAnimator: ObservableObject {
    @Published var isPresented = false
    @Published var disablesTransitionAnimation = false
}

final class LockScreenPanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class LockScreenPanelManager {
    private let nowPlayingViewModel: NowPlayingViewModel
    private let lockScreenManager: LockScreenManager
    private let generalSettingsViewModel: GeneralSettingsViewModel
    private let animator = LockScreenPanelAnimator()
    
    private var panelWindow: LockScreenPanelWindow?
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
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.nowPlayingViewModel = nowPlayingViewModel
        self.lockScreenManager = lockScreenManager
        self.generalSettingsViewModel = generalSettingsViewModel
        
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
        panelWindow?.orderOut(nil)
    }
    
    private func bindState() {
        Publishers.CombineLatest3(
            lockScreenManager.$isLocked.removeDuplicates(),
            nowPlayingViewModel.$snapshot,
            nowPlayingViewModel.$artworkImage
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isLocked, liveSnapshot, artworkImage in
            self?.syncPlaybackPresentation(
                isLocked: isLocked,
                liveSnapshot: liveSnapshot,
                artworkImage: artworkImage
            )
        }
        .store(in: &cancellables)
        
        generalSettingsViewModel.$displayLocation
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
            liveSnapshot: nowPlayingViewModel.snapshot,
            artworkImage: nowPlayingViewModel.artworkImage
        )
    }
    
    private func syncPlaybackPresentation(
        isLocked: Bool,
        liveSnapshot: NowPlayingSnapshot?,
        artworkImage: NSImage?
    ) {
        if let liveSnapshot {
            cachedSnapshot = liveSnapshot
            cachedArtworkImage = artworkImage
        } else if !isLocked {
            cachedSnapshot = nil
            cachedArtworkImage = nil
        }
        
        let resolvedSnapshot = resolvedSnapshot(isLocked: isLocked, liveSnapshot: liveSnapshot)
        let resolvedArtworkImage = resolvedArtworkImage(
            isLocked: isLocked,
            liveSnapshot: liveSnapshot,
            artworkImage: artworkImage
        )
        
        updatePresentation(
            isLocked: isLocked,
            snapshot: resolvedSnapshot,
            artworkImage: resolvedArtworkImage
        )
    }
    
    private func updatePresentation(
        isLocked: Bool,
        snapshot: NowPlayingSnapshot?,
        artworkImage: NSImage?
    ) {
        guard LockScreenSettings.isMediaPanelEnabled() else {
            hidePanel(animated: true)
            return
        }
        
        if isLocked, let snapshot {
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
            SkyLightOperator.shared.delegateWindow(window)
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
    
    private func hidePanel(animated: Bool) {
        animator.disablesTransitionAnimation = !animated
        animator.isPresented = false
        
        guard let window = panelWindow else { return }
        let delay = animated ? 0.22 : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak window] in
            guard let self else { return }
            
            let shouldRemainVisible =
            self.lockScreenManager.isLocked &&
            self.resolvedSnapshot(
                isLocked: self.lockScreenManager.isLocked,
                liveSnapshot: self.nowPlayingViewModel.snapshot
            ) != nil &&
            LockScreenSettings.isMediaPanelEnabled()
            
            guard !shouldRemainVisible else { return }
            
            window?.orderOut(nil)
        }
    }
    
    private func refreshPosition(animated: Bool) {
        guard let window = panelWindow, window.isVisible, let screen = currentScreen() else {
            return
        }
        
        let targetFrame = panelFrame(for: screen)
        let resolvedSnapshot = resolvedSnapshot(
            isLocked: lockScreenManager.isLocked,
            liveSnapshot: nowPlayingViewModel.snapshot
        )
        let resolvedArtworkImage = resolvedArtworkImage(
            isLocked: lockScreenManager.isLocked,
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
        isLocked: Bool,
        liveSnapshot: NowPlayingSnapshot?
    ) -> NowPlayingSnapshot? {
        liveSnapshot ?? (isLocked ? cachedSnapshot : nil)
    }
    
    private func resolvedArtworkImage(
        isLocked: Bool,
        liveSnapshot: NowPlayingSnapshot?,
        artworkImage: NSImage?
    ) -> NSImage? {
        if liveSnapshot != nil {
            return artworkImage
        }
        
        return isLocked ? cachedArtworkImage : nil
    }
    
    private func makeWindowIfNeeded() -> LockScreenPanelWindow {
        if let panelWindow {
            return panelWindow
        }
        
        let window = LockScreenPanelWindow(
            contentRect: NSRect(origin: .zero, size: LockScreenWindowLayout.canvasSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isFloatingPanel = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        window.hidesOnDeactivate = false
        window.isMovable = false
        window.hasShadow = false
        window.animationBehavior = .none
        
        panelWindow = window
        return window
    }
    
    private func currentScreen() -> NSScreen? {
        NSScreen.preferredLockScreen ??
        NSScreen.preferredNotchScreen(for: generalSettingsViewModel.displayLocation) ??
        NSScreen.main ??
        NSScreen.screens.first
    }
    
    private func panelFrame(for screen: NSScreen) -> NSRect {
        let canvasSize = LockScreenWindowLayout.canvasSize
        let size = LockScreenNowPlayingPanelView.panelSize
        let screenFrame = screen.frame
        
        let desiredPanelX = screenFrame.midX - size.width / 2
        let desiredPanelY = screenFrame.midY - size.height - 80
        
        let x = floor(desiredPanelX - (canvasSize.width - size.width) / 2)
        let y = floor(desiredPanelY - (canvasSize.height - size.height) / 2)
        
        return NSRect(origin: CGPoint(x: x, y: y), size: canvasSize)
    }
}
