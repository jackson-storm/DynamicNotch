internal import AppKit
import Combine
import SwiftUI

/// Hosts a small always-on-top lyrics panel that the user can drag anywhere on screen.
@MainActor
final class FloatingLyricsWindowManager {
    static let frameAutosaveName = "DynamicNotch.FloatingLyricsPanel"
    static let resetPositionNotification = Notification.Name("DynamicNotch.FloatingLyrics.resetPosition")
    private static let screenInset: CGFloat = 24
    private let lyricsPresentationSource = "floatingLyrics.panel"

    private let nowPlayingViewModel: NowPlayingViewModel
    private let settings: MediaAndFilesSettingsStore

    private static let hoverHiddenAlpha: CGFloat = 0.06

    private var panel: OverlayPanelWindow?
    private var hoverTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(nowPlayingViewModel: NowPlayingViewModel, settings: MediaAndFilesSettingsStore) {
        self.nowPlayingViewModel = nowPlayingViewModel
        self.settings = settings

        LyricsTranslationStore.shared.start(nowPlayingViewModel: nowPlayingViewModel, settings: settings)
        bindState()
        bindShortcuts()
    }

    func invalidate() {
        cancellables.removeAll()
        GlobalHotkeyManager.shared.unregister(.toggleFloatingLyrics)
        GlobalHotkeyManager.shared.unregister(.lyricsDelayLater)
        GlobalHotkeyManager.shared.unregister(.lyricsDelayEarlier)
        hidePanel()
        panel = nil
    }

    private func bindState() {
        let isPausedPublisher = nowPlayingViewModel.$snapshot
            .map { $0.map { !$0.isPlaying } ?? false }
            .removeDuplicates()
            // Ride out brief pauses (track changes, seeking) before hiding.
            .debounce(for: .seconds(2), scheduler: RunLoop.main)

        Publishers.CombineLatest4(
            Publishers.CombineLatest(
                settings.$isNowPlayingFloatingLyricsEnabled.removeDuplicates(),
                settings.$isNowPlayingLiveActivityEnabled.removeDuplicates()
            ),
            nowPlayingViewModel.$snapshot.map { $0 != nil }.removeDuplicates(),
            settings.$isFloatingLyricsHiddenWhenPaused.removeDuplicates(),
            isPausedPublisher.prepend(false)
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] enabledFlags, hasSnapshot, hidesWhenPaused, isPaused in
            let (isEnabled, isNowPlayingEnabled) = enabledFlags
            if isEnabled && isNowPlayingEnabled && hasSnapshot && !(hidesWhenPaused && isPaused) {
                self?.showPanel()
            } else {
                self?.hidePanel()
            }
        }
        .store(in: &cancellables)

        settings.$isFloatingLyricsHiddenOnHover
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateHoverTracking()
            }
            .store(in: &cancellables)

        settings.$isFloatingLyricsPositionLocked
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isLocked in
                self?.panel?.isMovable = !isLocked
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Self.resetPositionNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.resetPosition()
            }
            .store(in: &cancellables)

        settings.objectWillChange
            .receive(on: RunLoop.main)
            .map { [weak self] _ in self?.settings.floatingLyricsAppearance.panelSize }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyPanelSize()
            }
            .store(in: &cancellables)
    }

    private func bindShortcuts() {
        bindShortcut(
            .toggleFloatingLyrics,
            keyCode: settings.$floatingLyricsToggleShortcutKeyCode,
            modifiers: settings.$floatingLyricsToggleShortcutModifiers
        ) { [weak self] in
            self?.settings.isNowPlayingFloatingLyricsEnabled.toggle()
        }

        bindShortcut(
            .lyricsDelayLater,
            keyCode: settings.$lyricsDelayLaterShortcutKeyCode,
            modifiers: settings.$lyricsDelayLaterShortcutModifiers
        ) { [weak self] in
            self?.nowPlayingViewModel.adjustLyricsTrackDelay(by: 0.5)
        }

        bindShortcut(
            .lyricsDelayEarlier,
            keyCode: settings.$lyricsDelayEarlierShortcutKeyCode,
            modifiers: settings.$lyricsDelayEarlierShortcutModifiers
        ) { [weak self] in
            self?.nowPlayingViewModel.adjustLyricsTrackDelay(by: -0.5)
        }
    }

    private func bindShortcut(
        _ id: GlobalHotkeyManager.HotkeyID,
        keyCode: AnyPublisher<Int, Never>,
        modifiers: AnyPublisher<Int, Never>,
        action: @escaping @MainActor () -> Void
    ) {
        Publishers.CombineLatest(keyCode.removeDuplicates(), modifiers.removeDuplicates())
            .receive(on: RunLoop.main)
            .sink { keyCode, modifiers in
                guard keyCode >= 0 else {
                    GlobalHotkeyManager.shared.unregister(id)
                    return
                }

                GlobalHotkeyManager.shared.register(
                    id,
                    keyCode: UInt32(keyCode),
                    modifiers: NSEvent.ModifierFlags(rawValue: UInt(modifiers))
                ) {
                    Task { @MainActor in
                        action()
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Fades the panel out and lets clicks through while the pointer is over it; holding ⌘ keeps it interactive.
    private func updateHoverTracking() {
        let shouldTrack = settings.isFloatingLyricsHiddenOnHover && panel?.isVisible == true

        guard shouldTrack else {
            hoverTimer?.invalidate()
            hoverTimer = nil
            setHoverHidden(false)
            return
        }

        guard hoverTimer == nil else { return }
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let panel = self.panel else { return }
                let isPointerInside = panel.frame.contains(NSEvent.mouseLocation)
                let isCommandHeld = NSEvent.modifierFlags.contains(.command)
                self.setHoverHidden(isPointerInside && !isCommandHeld)
            }
        }
    }

    private func setHoverHidden(_ isHidden: Bool) {
        guard let panel else { return }
        let targetAlpha: CGFloat = isHidden ? Self.hoverHiddenAlpha : 1
        guard panel.alphaValue != targetAlpha else { return }

        panel.ignoresMouseEvents = isHidden
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            panel.animator().alphaValue = targetAlpha
        }
    }

    /// Moves the panel back to the bottom-left corner of the main screen.
    func resetPosition() {
        panel?.setFrameOrigin(defaultOrigin())
    }

    private func applyPanelSize() {
        guard let panel else { return }
        let size = settings.floatingLyricsAppearance.panelSize
        guard panel.frame.size != size else { return }

        // Keep the top-left corner fixed so the panel grows downward, away from where the user parked it.
        let topLeft = CGPoint(x: panel.frame.minX, y: panel.frame.maxY)
        panel.setFrame(
            CGRect(x: topLeft.x, y: topLeft.y - size.height, width: size.width, height: size.height),
            display: true
        )
    }

    private func showPanel() {
        let panel = panel ?? makePanel()
        self.panel = panel

        if !isFrameOnAnyScreen(panel.frame) {
            panel.setFrameOrigin(defaultOrigin())
        }

        nowPlayingViewModel.setLyricsPresentationActive(true, source: lyricsPresentationSource)
        panel.orderFrontRegardless()
        updateHoverTracking()
    }

    private func hidePanel() {
        nowPlayingViewModel.setLyricsPresentationActive(false, source: lyricsPresentationSource)
        panel?.orderOut(nil)
        updateHoverTracking()
    }

    private func makePanel() -> OverlayPanelWindow {
        let panel = OverlayPanelWindow(
            contentRect: CGRect(origin: defaultOrigin(), size: settings.floatingLyricsAppearance.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.allowsKeyWindow = false
        panel.allowsMainWindow = false
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovable = !settings.isFloatingLyricsPositionLocked
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        let rootView = FloatingLyricsView(
            nowPlayingViewModel: nowPlayingViewModel,
            settings: settings,
            onHide: { [weak self] in
                self?.settings.isNowPlayingFloatingLyricsEnabled = false
            }
        )
        let hostingView = DraggableHostingView(rootView: rootView)
        hostingView.sizingOptions = []
        panel.contentView = hostingView

        // Restores the last dragged position; AppKit keeps it updated as the panel moves.
        panel.setFrameAutosaveName(Self.frameAutosaveName)
        panel.setContentSize(settings.floatingLyricsAppearance.panelSize)

        return panel
    }

    private func defaultOrigin() -> CGPoint {
        let visibleFrame = NSScreen.main?.visibleFrame ?? .zero
        return CGPoint(
            x: visibleFrame.minX + Self.screenInset,
            y: visibleFrame.minY + Self.screenInset
        )
    }

    private func isFrameOnAnyScreen(_ frame: CGRect) -> Bool {
        NSScreen.screens.contains { screen in
            screen.visibleFrame.intersection(frame).width >= 60
        }
    }
}

/// Lets the whole panel act as a drag handle, since it has no title bar.
private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 1, window?.isMovable == true {
            window?.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}
