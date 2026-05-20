import SwiftUI

@MainActor
final class NotchTimerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let timerViewModel: TimerViewModel
    private let settingsViewModel: SettingsViewModel
    private let localTimerViewModel: LocalTimerViewModel

    init(
        notchViewModel: NotchViewModel,
        timerViewModel: TimerViewModel,
        settingsViewModel: SettingsViewModel,
        localTimerViewModel: LocalTimerViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.timerViewModel = timerViewModel
        self.settingsViewModel = settingsViewModel
        self.localTimerViewModel = localTimerViewModel
    }

    func handleTimer(_ event: TimerEvent) {
        switch event {
        case .started:
            if localTimerViewModel.state == .running || localTimerViewModel.state == .paused {
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
                        timerViewModel: timerViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .updated:
            if localTimerViewModel.state == .running || localTimerViewModel.state == .paused {
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
                        timerViewModel: timerViewModel,
                        settingsViewModel: settingsViewModel
                    )
                )
            )

        case .stopped:
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Media.timer.id))
        }
    }
}
