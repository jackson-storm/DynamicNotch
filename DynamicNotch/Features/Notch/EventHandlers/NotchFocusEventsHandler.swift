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
        case .FocusOn(let modeType):
            guard settingsViewModel.isLiveActivityEnabled(.focus) else { return }
            notchViewModel.send(.showLiveActivity(FocusOnNotchContent(settingsViewModel: settingsViewModel, focusModeType: modeType)))

        case .FocusOff(let modeType):
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Focus.active.id))
            guard settingsViewModel.isTemporaryActivityEnabled(.focusOff) else { return }
            notchViewModel.send(.showTemporaryNotification(FocusOffNotchContent(settingsViewModel: settingsViewModel, focusModeType: modeType), duration: settingsViewModel.temporaryActivityDuration(for: .focusOff))
            )
        }
    }
}
