import SwiftUI
internal import AppKit
import Combine

private enum DeferredNowPlayingHideReason {
    case stopped
    case pauseTimer
}

@MainActor
final class NotchMediaEventsHandler {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private var deferredNowPlayingHideWhileExpanded: DeferredNowPlayingHideReason?
    private var nowPlayingPauseHideWorkItem: DispatchWorkItem?
    private var isNowPlayingHiddenForPauseTimer = false
    private var cancellables = Set<AnyCancellable>()

    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
        setupWorkspaceObservation()
    }

    func handleNowPlaying(_ event: NowPlayingEvent) {
        switch event {
        case .started:
            cancelDeferredNowPlayingHide()
            isNowPlayingHiddenForPauseTimer = false
            guard settingsViewModel.isLiveActivityEnabled(.nowPlaying) else { return }
            showNowPlayingLiveActivity()
            syncNowPlayingPlaybackState()

        case .stopped:
            cancelNowPlayingPauseHideTimer()
            isNowPlayingHiddenForPauseTimer = false
            if isExpandedNowPlayingVisible {
                deferredNowPlayingHideWhileExpanded = .stopped
                return
            }

            deferredNowPlayingHideWhileExpanded = nil
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.nowPlaying.id))

        case let .playbackStateChanged(isPlaying):
            guard settingsViewModel.isLiveActivityEnabled(.nowPlaying) else {
                cancelDeferredNowPlayingHide()
                return
            }

            if isPlaying {
                cancelDeferredNowPlayingHide()
                isNowPlayingHiddenForPauseTimer = false
                showNowPlayingLiveActivity()
            } else {
                syncNowPlayingPlaybackState()
            }
        }
    }

    func cancelDeferredNowPlayingHide() {
        deferredNowPlayingHideWhileExpanded = nil
        cancelNowPlayingPauseHideTimer()
    }

    func handleExpansionChange(isExpanded: Bool) {
        guard let deferredHideReason = deferredNowPlayingHideWhileExpanded else { return }
        guard !isExpanded else { return }

        switch deferredHideReason {
        case .stopped:
            guard nowPlayingViewModel.hasActiveSession == false else {
                deferredNowPlayingHideWhileExpanded = nil
                return
            }

            deferredNowPlayingHideWhileExpanded = nil
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.nowPlaying.id))

        case .pauseTimer:
            guard settingsViewModel.mediaAndFiles.isNowPlayingPauseHideTimerEnabled else {
                deferredNowPlayingHideWhileExpanded = nil
                isNowPlayingHiddenForPauseTimer = false
                showNowPlayingLiveActivity()
                return
            }

            guard nowPlayingViewModel.snapshot?.isPlaying != true else {
                deferredNowPlayingHideWhileExpanded = nil
                isNowPlayingHiddenForPauseTimer = false
                return
            }

            deferredNowPlayingHideWhileExpanded = nil
            hideNowPlayingForPauseTimer()
        }
    }

    func syncNowPlayingPlaybackState() {
        guard settingsViewModel.isLiveActivityEnabled(.nowPlaying) else {
            cancelDeferredNowPlayingHide()
            return
        }

        guard nowPlayingViewModel.hasActiveSession else {
            cancelDeferredNowPlayingHide()
            isNowPlayingHiddenForPauseTimer = false
            return
        }

        guard nowPlayingViewModel.snapshot?.isPlaying != true else {
            cancelDeferredNowPlayingHide()
            isNowPlayingHiddenForPauseTimer = false
            showNowPlayingLiveActivity()
            return
        }

        guard settingsViewModel.mediaAndFiles.isNowPlayingPauseHideTimerEnabled else {
            cancelDeferredNowPlayingHide()
            isNowPlayingHiddenForPauseTimer = false
            showNowPlayingLiveActivity()
            return
        }

        guard !isNowPlayingHiddenForPauseTimer else { return }
        scheduleNowPlayingPauseHide()
    }

    private var isExpandedNowPlayingVisible: Bool {
        notchViewModel.notchModel.liveActivityContent?.id == NotchContentRegistry.Media.nowPlaying.id &&
        notchViewModel.notchModel.isLiveActivityExpanded
    }
    
    private func setupWorkspaceObservation() {
        NSWorkspace.shared.publisher(for: \.frontmostApplication)
            .sink { [weak self] app in
                guard let self else { return }
                self.handleFrontmostApplicationChange(app)
            }
            .store(in: &cancellables)
    }

    private func handleFrontmostApplicationChange(_ app: NSRunningApplication?) {
        guard settingsViewModel.isLiveActivityEnabled(.nowPlaying),
              let snapshot = nowPlayingViewModel.snapshot,
              let source = snapshot.playbackSource else {
            return
        }

        var isSourceActive = false
        if let bundleId = source.preferredBundleIdentifier, bundleId == app?.bundleIdentifier {
            isSourceActive = true
        } else if let pid = source.validProcessIdentifier, pid == app?.processIdentifier ?? 0 {
            isSourceActive = true
        }

        if isSourceActive {
            deferredNowPlayingHideWhileExpanded = nil
            cancelNowPlayingPauseHideTimer()
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.nowPlaying.id))
        } else {
            syncNowPlayingPlaybackState()
        }
    }

    private func showNowPlayingLiveActivity() {
        guard nowPlayingViewModel.hasActiveSession else { return }
        
        if let source = nowPlayingViewModel.snapshot?.playbackSource,
           let app = NSWorkspace.shared.frontmostApplication {
            
            var isSourceActive = false
            if let bundleId = source.preferredBundleIdentifier, bundleId == app.bundleIdentifier {
                isSourceActive = true
            } else if let pid = source.validProcessIdentifier, pid == app.processIdentifier {
                isSourceActive = true
            }
            
            if isSourceActive {
                return
            }
        }

        notchViewModel.send(
            .showLiveActivity(
                NowPlayingNotchContent(
                    nowPlayingViewModel: nowPlayingViewModel,
                    settings: settingsViewModel.mediaAndFiles,
                    applicationSettings: settingsViewModel.application,
                    onOpenPlaybackSource: { [weak notchViewModel] in
                        notchViewModel?.handleOutsideClick()
                    }
                )
            )
        )
    }

    private func scheduleNowPlayingPauseHide() {
        cancelNowPlayingPauseHideTimer()

        let delay = TimeInterval(settingsViewModel.mediaAndFiles.nowPlayingPauseHideDelay)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.nowPlayingPauseHideWorkItem = nil

            guard self.settingsViewModel.mediaAndFiles.isNowPlayingPauseHideTimerEnabled else { return }
            guard self.nowPlayingViewModel.hasActiveSession else { return }
            guard self.nowPlayingViewModel.snapshot?.isPlaying != true else { return }

            if self.isExpandedNowPlayingVisible {
                self.deferredNowPlayingHideWhileExpanded = .pauseTimer
                return
            }

            self.hideNowPlayingForPauseTimer()
        }

        nowPlayingPauseHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelNowPlayingPauseHideTimer() {
        nowPlayingPauseHideWorkItem?.cancel()
        nowPlayingPauseHideWorkItem = nil
    }

    private func hideNowPlayingForPauseTimer() {
        cancelNowPlayingPauseHideTimer()
        deferredNowPlayingHideWhileExpanded = nil
        isNowPlayingHiddenForPauseTimer = true
        notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.nowPlaying.id))
    }
}
