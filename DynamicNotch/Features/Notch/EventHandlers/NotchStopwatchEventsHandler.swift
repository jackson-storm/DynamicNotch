import SwiftUI

@MainActor
final class NotchStopwatchEventsHandler {
    private let notchViewModel: NotchViewModel
    private let stopwatchViewModel: StopwatchViewModel

    init(notchViewModel: NotchViewModel, stopwatchViewModel: StopwatchViewModel) {
        self.notchViewModel = notchViewModel
        self.stopwatchViewModel = stopwatchViewModel
    }

    func handleStopwatchStateChanged(_ state: StopwatchState) {
        switch state {
        case .running, .paused:
            PomodoroViewModel.shared.reset()
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.pomodoro.id))
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.HomePage.active.id))
            notchViewModel.send(
                .showLiveActivity(StopwatchNotchContent(viewModel: stopwatchViewModel))
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.stopwatch.id))
        }
    }
}
