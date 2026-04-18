import SwiftUI

@MainActor
final class NotchFocusEventsHandler {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
    }

    func handleFocus(_ event: FocusEvent) {
        switch event {
        case .FocusOn:
            guard settingsViewModel.isLiveActivityEnabled(.focus) else { return }
            notchViewModel.send(.showLiveActivity(FocusOnNotchContent(settingsViewModel: settingsViewModel)))

        case .FocusOff:
            notchViewModel.send(.hideLiveActivity(id: "focus.on"))
            guard settingsViewModel.isTemporaryActivityEnabled(.focusOff) else { return }
            notchViewModel.send(.showTemporaryNotification(FocusOffNotchContent(settingsViewModel: settingsViewModel), duration: settingsViewModel.temporaryActivityDuration(for: .focusOff))
            )
        }
    }
}
