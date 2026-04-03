internal import AppKit
import Combine
import SwiftUI

@MainActor
final class LockScreenLiveActivityAnimator: ObservableObject {
    @Published var scale: CGFloat = 1
    @Published var opacity: Double = 0
}

private struct LockScreenOverlayGeometry: Equatable {
    let baseWidth: CGFloat
    let baseHeight: CGFloat
    let scale: CGFloat
}

@MainActor
final class LockScreenLiveActivityWindowManager {
    private let notchViewModel: NotchViewModel
    private let lockScreenManager: LockScreenManager
    private let settingsViewModel: SettingsViewModel
    private let animator = LockScreenLiveActivityAnimator()

    private var overlayWindow: OverlayPanelWindow?
    private var hostingView: NSHostingView<LockScreenLiveActivityOverlayView>?
    private var appObservers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private var cancellables = Set<AnyCancellable>()
    private var hasDelegatedWindow = false

    init(
        notchViewModel: NotchViewModel,
        lockScreenManager: LockScreenManager,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
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
        releaseOverlayResources()
    }

    private func bindState() {
        let geometryPublisher = notchViewModel.$notchModel
            .map { model in
                LockScreenOverlayGeometry(
                    baseWidth: model.baseWidth,
                    baseHeight: model.baseHeight,
                    scale: model.scale
                )
            }

        Publishers.CombineLatest3(
            lockScreenManager.$isLocked.removeDuplicates(),
            lockScreenManager.$isPreparingLock.removeDuplicates(),
            lockScreenManager.$isLockIdle.removeDuplicates()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] isLocked, isPreparingLock, isLockIdle in
            self?.syncPresentation(
                isLocked: isLocked,
                isPreparingLock: isPreparingLock,
                isLockIdle: isLockIdle
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

        geometryPublisher
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
                    self?.syncCurrentPresentation()
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

        workspaceObservers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
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
        syncPresentation(
            isLocked: lockScreenManager.isLocked,
            isPreparingLock: lockScreenManager.isPreparingLock,
            isLockIdle: lockScreenManager.isLockIdle
        )
    }

    private func syncPresentation(
        isLocked: Bool,
        isPreparingLock: Bool,
        isLockIdle: Bool
    ) {
        guard LockScreenSettings.isLiveActivityEnabled() else {
            hideOverlay(animated: true, releaseResources: true)
            return
        }

        if isLocked || isPreparingLock {
            showLockedOverlay()
        } else if !isLockIdle {
            showUnlockingOverlay()
        } else {
            hideOverlay(animated: true)
        }
    }

    private func showLockedOverlay() {
        presentOverlay(animatedIn: false)

        animator.scale = 1
        animator.opacity = 1
    }

    private func showUnlockingOverlay() {
        presentOverlay(animatedIn: false)

        animator.scale = 1
        animator.opacity = 1
    }

    private func presentOverlay(animatedIn: Bool) {
        guard let screen = currentScreen() else { return }

        let size = overlaySize
        let window = makeWindowIfNeeded()
        let targetFrame = overlayFrame(for: size, on: screen)

        if window.frame != targetFrame {
            window.setFrame(targetFrame, display: true)
        }

        let rootView = LockScreenLiveActivityOverlayView(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            lockScreenManager: lockScreenManager,
            animator: animator
        )

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

        if animatedIn {
            animator.scale = 0.92
            animator.opacity = 0

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.animator.scale = 1
                }

                withAnimation(.easeOut(duration: 0.18)) {
                    self.animator.opacity = 1
                }
            }
        }
    }

    private func hideOverlay(animated: Bool, releaseResources: Bool = false) {
        guard let window = overlayWindow else {
            if releaseResources {
                releaseOverlayResources()
            }
            return
        }

        let delay = animated ? 0.2 : 0

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                animator.scale = 0.96
            }

            withAnimation(.easeOut(duration: 0.14)) {
                animator.opacity = 0
            }
        } else {
            animator.scale = 1
            animator.opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak window] in
            guard let self else { return }

            let shouldRemainVisible = LockScreenSettings.isLiveActivityEnabled() &&
                (self.lockScreenManager.isLocked || !self.lockScreenManager.isLockIdle)

            guard !shouldRemainVisible else { return }
            window?.orderOut(nil)

            if releaseResources {
                self.releaseOverlayResources()
            }
        }
    }

    private func releaseOverlayResources() {
        animator.scale = 1
        animator.opacity = 0

        overlayWindow?.orderOut(nil)
        overlayWindow?.contentView = nil
        hostingView = nil
        overlayWindow = nil
        hasDelegatedWindow = false
    }

    private func refreshPosition(animated: Bool) {
        guard let window = overlayWindow, window.isVisible, let screen = currentScreen() else {
            return
        }

        let targetFrame = overlayFrame(for: overlaySize, on: screen)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().setFrame(targetFrame, display: true)
            }
        } else {
            window.setFrame(targetFrame, display: true)
        }

        hostingView?.frame = NSRect(origin: .zero, size: targetFrame.size)
        hostingView?.rootView = LockScreenLiveActivityOverlayView(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            lockScreenManager: lockScreenManager,
            animator: animator
        )

        window.orderFrontRegardless()
    }

    private func makeWindowIfNeeded() -> OverlayPanelWindow {
        if let overlayWindow {
            return overlayWindow
        }

        let window = OverlayPanelFactory.makePanel(
            frame: NSRect(origin: .zero, size: overlaySize),
            level: OverlayWindowLevel.shieldingOverlay
        )

        overlayWindow = window
        return window
    }

    private var overlaySize: CGSize {
        OverlayWindowLayout.lockScreenCanvasSize
    }

    private func overlayFrame(for size: CGSize, on screen: NSScreen) -> NSRect {
        OverlayWindowLayout.topAnchoredFrame(on: screen, size: size)
    }

    private func currentScreen() -> NSScreen? {
        NSScreen.preferredLockScreen ??
        NSScreen.preferredNotchScreen(for: settingsViewModel.displayLocation) ??
        NSScreen.screens.first
    }
}

private struct LockScreenLiveActivityOverlayView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    @ObservedObject var animator: LockScreenLiveActivityAnimator

    private var content: LockScreenNotchContent {
        LockScreenNotchContent(lockScreenManager: lockScreenManager)
    }

    private var contentSize: CGSize {
        content.size(
            baseWidth: notchViewModel.notchModel.baseWidth,
            baseHeight: notchViewModel.notchModel.baseHeight
        )
    }

    private var cornerRadius: (top: CGFloat, bottom: CGFloat) {
        content.cornerRadius(baseRadius: notchViewModel.notchModel.baseHeight / 3)
    }

    var body: some View {
        NotchShape(
            topCornerRadius: cornerRadius.top,
            bottomCornerRadius: cornerRadius.bottom
        )
        .fill(.black)
        .stroke(
            settingsViewModel.isShowNotchStrokeEnabled ? content.strokeColor : Color.clear,
            lineWidth: settingsViewModel.notchStrokeWidth
        )
        .overlay {
            LockScreenNotchView(lockScreenManager: lockScreenManager)
                .environment(\.notchScale, notchViewModel.notchModel.scale)
        }
        .customNotchPressable(
            notchViewModel: notchViewModel,
            isPressed: $notchViewModel.isPressed,
            baseSize: notchViewModel.notchModel.size
        )
        .frame(width: contentSize.width, height: contentSize.height)
        .scaleEffect(animator.scale)
        .opacity(animator.opacity)
        .offset(y: 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
