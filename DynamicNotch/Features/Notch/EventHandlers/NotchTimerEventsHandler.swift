import SwiftUI

@MainActor
final class NotchTimerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let timerViewModel: TimerViewModel

    init(
        notchViewModel: NotchViewModel,
        timerViewModel: TimerViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.timerViewModel = timerViewModel
    }

    func handleTimer(_ event: TimerEvent) {
        switch event {
        case .started:
            guard timerViewModel.snapshot != nil else { return }
            notchViewModel.send(.showLiveActivity(TimerNotchContent(timerViewModel: timerViewModel)))

        case .updated:
            guard timerViewModel.snapshot != nil else { return }
            notchViewModel.send(.showLiveActivity(TimerNotchContent(timerViewModel: timerViewModel)))

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: TimerNotchContent.activityID))
        }
    }
}
