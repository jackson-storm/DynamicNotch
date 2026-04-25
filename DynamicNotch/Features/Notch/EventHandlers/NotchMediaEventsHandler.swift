import SwiftUI

private enum DeferredNowPlayingHideReason {
    case stopped
    case pauseTimer
}

@MainActor
final class NotchMediaEventsHandler {
    private let notchViewModel: NotchViewModel
    private let downloadViewModel: DownloadViewModel
    private let airDropViewModel: AirDropNotchViewModel
    private let settingsViewModel: SettingsViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private var deferredNowPlayingHideWhileExpanded: DeferredNowPlayingHideReason?
    private var nowPlayingPauseHideWorkItem: DispatchWorkItem?
    private var isNowPlayingHiddenForPauseTimer = false

    init(
        notchViewModel: NotchViewModel,
        downloadViewModel: DownloadViewModel,
        airDropViewModel: AirDropNotchViewModel,
        settingsViewModel: SettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.downloadViewModel = downloadViewModel
        self.airDropViewModel = airDropViewModel
        self.settingsViewModel = settingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
    }

    func handleDownload(_ event: DownloadEvent) {
        switch event {
        case .started:
            guard settingsViewModel.isLiveActivityEnabled(.downloads) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    DownloadNotchContent(
                        downloadViewModel: downloadViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.download.id))
        }
    }

    func handleAirDrop(_ event: AirDropEvent) {
        switch event {
        case .dragStarted:
            guard settingsViewModel.isLiveActivityEnabled(.dragAndDrop) else { return }
            hideInactiveDragAndDropActivities()
            showDragAndDropLiveActivity()

        case .dragEnded, .dropped:
            hideDragAndDropActivities()
        }
    }

    func refreshDragAndDropPresentation() {
        hideDragAndDropActivities()
        guard airDropViewModel.isDraggingFile else { return }
        handleAirDrop(.dragStarted)
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

    private func showDragAndDropLiveActivity() {
        switch settingsViewModel.mediaAndFiles.dragAndDropActivityMode {
        case .airDrop:
            notchViewModel.send(
                .showLiveActivity(
                    AirDropNotchContent(
                        airDropViewModel: airDropViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .tray:
            notchViewModel.send(
                .showLiveActivity(
                    TrayNotchContent(
                        airDropViewModel: airDropViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .combined:
            notchViewModel.send(
                .showLiveActivity(
                    DragAndDropCombinedNotchContent(
                        airDropViewModel: airDropViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )
        }
    }

    private func hideDragAndDropActivities() {
        NotchContentRegistry.DragAndDrop.liveActivityIDs.forEach { id in
            notchViewModel.send(.hideLiveActivity(id: id))
        }
    }

    private func hideInactiveDragAndDropActivities() {
        let activeID: String

        switch settingsViewModel.mediaAndFiles.dragAndDropActivityMode {
        case .airDrop:
            activeID = NotchContentRegistry.DragAndDrop.airDrop.id
        case .tray:
            activeID = NotchContentRegistry.DragAndDrop.tray.id
        case .combined:
            activeID = NotchContentRegistry.DragAndDrop.combined.id
        }

        NotchContentRegistry.DragAndDrop.liveActivityIDs
            .filter { $0 != activeID }
            .forEach { id in
                notchViewModel.send(.hideLiveActivity(id: id))
            }
    }

    private func showNowPlayingLiveActivity() {
        guard nowPlayingViewModel.hasActiveSession else { return }

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
