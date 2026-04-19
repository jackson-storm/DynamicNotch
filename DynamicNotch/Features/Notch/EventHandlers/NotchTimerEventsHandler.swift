import SwiftUI

@MainActor
final class NotchTimerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let timerViewModel: TimerViewModel
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        timerViewModel: TimerViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.timerViewModel = timerViewModel
        self.settingsViewModel = settingsViewModel
    }

    func handleTimer(_ event: TimerEvent) {
        switch event {
        case .started:
            guard settingsViewModel.isLiveActivityEnabled(.timer) else {
                notchViewModel.send(.hideLiveActivity(id: TimerNotchContent.activityID))
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
            guard settingsViewModel.isLiveActivityEnabled(.timer) else {
                notchViewModel.send(.hideLiveActivity(id: TimerNotchContent.activityID))
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
            notchViewModel.send(.hideLiveActivity(id: TimerNotchContent.activityID))
        }
    }
}
