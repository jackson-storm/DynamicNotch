import SwiftUI

@MainActor
final class NotchLocalTimerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let localTimerViewModel: LocalTimerViewModel
    private let timerViewModel: TimerViewModel

    init(
        notchViewModel: NotchViewModel,
        localTimerViewModel: LocalTimerViewModel,
        timerViewModel: TimerViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.localTimerViewModel = localTimerViewModel
        self.timerViewModel = timerViewModel
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
                    LocalTimerNotchContent(
                        localTimerViewModel: localTimerViewModel
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.localTimer.id))
        }
    }
}
