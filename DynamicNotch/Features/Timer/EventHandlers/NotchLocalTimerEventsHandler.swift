import SwiftUI

@MainActor
final class NotchLocalTimerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let localTimerViewModel: LocalTimerViewModel
    private let timerViewModel: TimerViewModel
    private let settingsViewModel: SettingsViewModel
    private let timerSoundPlayer: any TimerSoundPlaying

    init(
        notchViewModel: NotchViewModel,
        localTimerViewModel: LocalTimerViewModel,
        timerViewModel: TimerViewModel,
        settingsViewModel: SettingsViewModel,
        timerSoundPlayer: any TimerSoundPlaying
    ) {
        self.notchViewModel = notchViewModel
        self.localTimerViewModel = localTimerViewModel
        self.timerViewModel = timerViewModel
        self.settingsViewModel = settingsViewModel
        self.timerSoundPlayer = timerSoundPlayer

        self.localTimerViewModel.onTimerFinished = { [weak self] in
            guard let self else { return }
            self.handleLocalTimerFinished()
        }
    }

    convenience init(
        notchViewModel: NotchViewModel,
        localTimerViewModel: LocalTimerViewModel,
        timerViewModel: TimerViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.init(
            notchViewModel: notchViewModel,
            localTimerViewModel: localTimerViewModel,
            timerViewModel: timerViewModel,
            settingsViewModel: settingsViewModel,
            timerSoundPlayer: TimerSoundPlayer.shared
        )
    }

    func handleLocalTimerStateChanged(_ state: LocalTimerState) {
        switch state {
        case .running, .paused:
            // Conflict protection: If the system timer is actively running, abort.
            if timerViewModel.snapshot != nil && timerViewModel.snapshot!.isPaused == false {
                return
            }
            
            notchViewModel.send(
                .showLiveActivity(
                    TimerNotchContent(
                        source: .local(localTimerViewModel)
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.localTimer.id))
        }
    }

    func handleLocalTimerFinished() {
        timerSoundPlayer.play(
            sound: settingsViewModel.mediaAndFiles.timerSound,
            isSoundEnabled: settingsViewModel.mediaAndFiles.isTimerSoundEnabled,
            loop: true
        )

        notchViewModel.send(
            .showLiveActivity(
                TimerFinishedNotchContent(
                    onDismiss: { [weak self] in
                        guard let self else { return }
                        self.timerSoundPlayer.stop()
                        self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timerFinished.id))
                    },
                    onRestart: { [weak self] in
                        guard let self else { return }
                        self.timerSoundPlayer.stop()
                        self.notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timerFinished.id))
                        self.localTimerViewModel.restart()
                    }
                )
            )
        )
    }
}

