import SwiftUI

@MainActor
final class NotchTimerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let timerViewModel: TimerViewModel
    private let settingsViewModel: SettingsViewModel
    private let stopwatchViewModel: StopwatchViewModel

    init(
        notchViewModel: NotchViewModel,
        timerViewModel: TimerViewModel,
        settingsViewModel: SettingsViewModel,
        stopwatchViewModel: StopwatchViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.timerViewModel = timerViewModel
        self.settingsViewModel = settingsViewModel
        self.stopwatchViewModel = stopwatchViewModel
    }

    func handleTimer(_ event: TimerEvent) {
        switch event {
        case .started:
            if stopwatchViewModel.state == .running || stopwatchViewModel.state == .paused {
                return
            }
            guard settingsViewModel.isLiveActivityEnabled(.timer) else {
                notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
                return
            }
            guard timerViewModel.snapshot != nil else { return }
            notchViewModel.send(
                .showLiveActivity(
                    TimerNotchContent(
                        source: .system(timerViewModel),
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .updated:
            if stopwatchViewModel.state == .running || stopwatchViewModel.state == .paused {
                return
            }
            guard settingsViewModel.isLiveActivityEnabled(.timer) else {
                notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
                return
            }
            guard timerViewModel.snapshot != nil else { return }
            notchViewModel.send(
                .showLiveActivity(
                    TimerNotchContent(
                        source: .system(timerViewModel),
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
        }
    }
}
