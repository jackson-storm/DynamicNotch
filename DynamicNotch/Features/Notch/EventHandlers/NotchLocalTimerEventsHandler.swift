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
            PomodoroViewModel.shared.reset()
            notchViewModel.send(
                .hideLiveActivity(id: NotchContentRegistry.Media.pomodoro.id)
            )
            notchViewModel.send(
                .hideLiveActivity(id: NotchContentRegistry.HomePage.active.id)
            )
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
}
