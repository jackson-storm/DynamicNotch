import SwiftUI

@MainActor
final class NotchMediaEventsHandler {
    private let notchViewModel: NotchViewModel
    private let downloadViewModel: DownloadViewModel
    private let airDropViewModel: AirDropNotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel
    private let nowPlayingViewModel: NowPlayingViewModel
    private var deferredNowPlayingHideWhileExpanded = false

    init(
        notchViewModel: NotchViewModel,
        downloadViewModel: DownloadViewModel,
        airDropViewModel: AirDropNotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel,
        nowPlayingViewModel: NowPlayingViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.downloadViewModel = downloadViewModel
        self.airDropViewModel = airDropViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
        self.nowPlayingViewModel = nowPlayingViewModel
    }

    func handleDownload(_ event: DownloadEvent) {
        switch event {
        case .started:
            guard generalSettingsViewModel.isLiveActivityEnabled(.downloads) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    DownloadNotchContent(
                        downloadViewModel: downloadViewModel,
                        generalSettingsViewModel: generalSettingsViewModel
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: "download.active"))
        }
    }

    func handleAirDrop(_ event: AirDropEvent) {
        switch event {
        case .dragStarted:
            guard generalSettingsViewModel.isLiveActivityEnabled(.airDrop) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    AirDropNotchContent(
                        airDropViewModel: airDropViewModel,
                        generalSettingsViewModel: generalSettingsViewModel
                    )
                )
            )

        case .dragEnded, .dropped:
            notchViewModel.send(.hideLiveActivity(id: "airdrop"))
        }
    }

    func handleNowPlaying(_ event: NowPlayingEvent) {
        switch event {
        case .started:
            deferredNowPlayingHideWhileExpanded = false
            guard generalSettingsViewModel.isLiveActivityEnabled(.nowPlaying) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    NowPlayingNotchContent(nowPlayingViewModel: nowPlayingViewModel)
                )
            )

        case .stopped:
            if isExpandedNowPlayingVisible {
                deferredNowPlayingHideWhileExpanded = true
                return
            }

            deferredNowPlayingHideWhileExpanded = false
            notchViewModel.send(.hideLiveActivity(id: "nowPlaying"))
        }
    }

    func cancelDeferredNowPlayingHide() {
        deferredNowPlayingHideWhileExpanded = false
    }

    func handleExpansionChange(isExpanded: Bool) {
        guard deferredNowPlayingHideWhileExpanded else { return }
        guard !isExpanded else { return }
        guard nowPlayingViewModel.hasActiveSession == false else {
            deferredNowPlayingHideWhileExpanded = false
            return
        }

        deferredNowPlayingHideWhileExpanded = false
        notchViewModel.send(.hideLiveActivity(id: "nowPlaying"))
    }

    private var isExpandedNowPlayingVisible: Bool {
        notchViewModel.notchModel.liveActivityContent?.id == "nowPlaying" &&
        notchViewModel.notchModel.isLiveActivityExpanded
    }
}
