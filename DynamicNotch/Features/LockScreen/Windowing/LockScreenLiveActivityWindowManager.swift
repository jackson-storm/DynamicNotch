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
        
        notchViewModel.$notchModel
            .map(\.content?.id)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncCurrentPresentation()
            }
            .store(in: &cancellables)
        
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
        let isLockScreenContentReady = notchViewModel.notchModel.content?.id == NotchContentRegistry.LockScreen.activity.id
        
        guard LockScreenSettings.isLiveActivityEnabled() else {
            hideOverlay(animated: true, releaseResources: true)
            return
        }
        
        if isLocked {
            guard isLockScreenContentReady else {
                hideOverlay(animated: false)
                return
            }
            
            showLockedOverlay()
        } else if isPreparingLock {
            if isLockScreenContentReady {
                showLockedOverlay()
            } else {
                hideOverlay(animated: false)
            }
        } else if !isLockIdle {
            showUnlockingOverlay()
        } else {
            hideOverlay(animated: true)
        }
    }
    
    private func showLockedOverlay() {
        presentOverlay(animatedIn: false)
    }
    
    private func showUnlockingOverlay() {
        presentOverlay(animatedIn: false)
    }
    
    private func presentOverlay(animatedIn: Bool) {
        guard let screen = currentScreen() else { return }
        
        let window = makeWindowIfNeeded(for: screen)
        let targetFrame = overlayFrame(on: screen)
        
        if window.frame != targetFrame {
            window.setFrame(targetFrame, display: true)
        }
        
        let rootView = LockScreenLiveActivityOverlayView(
            notchViewModel: notchViewModel,
            settingsViewModel: settingsViewModel,
            lockScreenManager: lockScreenManager,
            animator: animator
        )
        
        if animatedIn {
            animator.scale = 0.92
            animator.opacity = 0
        } else {
            animator.scale = 1
            animator.opacity = 1
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
            SkyLightOperator.shared.delegateWindow(window, to: .lockScreenNotchOverlay)
            hasDelegatedWindow = true
        }
        
        window.orderFrontRegardless()
        
        if animatedIn {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                    self.animator.scale = 1
                    self.animator.opacity = 1
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
        
        let targetFrame = overlayFrame(on: screen)
        
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
    
    private func makeWindowIfNeeded(for screen: NSScreen) -> OverlayPanelWindow {
        if let overlayWindow {
            return overlayWindow
        }
        
        let window = OverlayPanelFactory.makePanel(
            frame: overlayFrame(on: screen),
            level: OverlayWindowLevel.lockScreenNotch
        )
        
        overlayWindow = window
        return window
    }
    
    private func overlayFrame(on screen: NSScreen) -> NSRect {
        OverlayWindowLayout.lockScreenCanvasFrame(on: screen)
    }
    
    private func currentScreen() -> NSScreen? {
        NSScreen.preferredLockScreen ??
        NSScreen.preferredNotchScreen(for: settingsViewModel) ??
        NSScreen.screens.first
    }
}

private struct LockScreenLiveActivityOverlayView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var lockScreenManager: LockScreenManager
    @ObservedObject var animator: LockScreenLiveActivityAnimator
    
    var body: some View {
        notchSurface
            .overlay {
                contentOverlay
                    .clipShape(Rectangle())
            }
            .environment(\.colorScheme, .dark)
            .frame(
                width: notchViewModel.interactiveNotchSize.width,
                height: notchViewModel.interactiveNotchSize.height
            )
            .customNotchPressable(
                notchViewModel: notchViewModel,
                isPressed: $notchViewModel.isPressed,
                baseSize: notchViewModel.interactiveNotchSize
            )
            .scaleEffect(animator.scale)
            .opacity(animator.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(notchViewModel.animations.strokeVisibility, value: settingsViewModel.isShowNotchStrokeEnabled)
            .animation(notchViewModel.animations.notchVisibility, value: notchViewModel.showNotch)
    }
    
    @ViewBuilder
    private var notchSurface: some View {
        NotchBackgroundSurface(
            style: settingsViewModel.application.notchBackgroundStyle,
            topCornerRadius: notchViewModel.interactiveCornerRadius.top,
            bottomCornerRadius: notchViewModel.interactiveCornerRadius.bottom,
            strokeColor: settingsViewModel.isShowNotchStrokeEnabled ? visibleStrokeColor : .clear,
            strokeWidth: settingsViewModel.notchStrokeWidth
        )
    }
    
    private var visibleStrokeColor: Color {
        notchViewModel.notchModel.content?.strokeColor ?? notchViewModel.cachedStrokeColor
    }
    
    @ViewBuilder
    private var contentOverlay: some View {
        if let content = notchViewModel.notchModel.content {
            renderedContentView(for: content)
                .id(notchViewModel.notchModel.presentationID)
                .transition(
                    notchViewModel.contentTransition(
                        notchWidth: notchViewModel.interactiveNotchSize.width,
                        notchHeight: notchViewModel.interactiveNotchSize.height,
                        baseHeight: notchViewModel.notchModel.baseHeight,
                        isExpandedPresentation: notchViewModel.notchModel.isPresentingExpandedLiveActivity
                    )
                )
        }
    }
    
    @MainActor
    @ViewBuilder
    private func renderedContentView(for content: NotchContentProtocol) -> some View {
        if notchViewModel.notchModel.isPresentingExpandedLiveActivity {
            content.makeExpandedView()
        } else {
            content.makeView()
        }
    }
}
