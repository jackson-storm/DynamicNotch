import SwiftUI

@MainActor
final class NotchFocusEventsHandler {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel

    // FocusService re-emits FocusOn on every metadata update while focus stays
    // active, so in auto-hide mode the notification must only fire on a real
    // off->on transition or a mode change.
    private var lastShownFocusMode: FocusModeType?

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

            let content = FocusOnNotchContent(settingsViewModel: settingsViewModel, focusModeType: modeType)

            if settingsViewModel.isTemporaryActivityEnabled(.focusOn) {
                guard lastShownFocusMode != modeType else { return }
                lastShownFocusMode = modeType
                notchViewModel.send(.showTemporaryNotification(content, duration: settingsViewModel.temporaryActivityDuration(for: .focusOn)))
            } else {
                lastShownFocusMode = modeType
                notchViewModel.send(.showLiveActivity(content))
            }

        case .FocusOff(let modeType):
            lastShownFocusMode = nil
            if notchViewModel.notchModel.temporaryNotificationContent?.id == NotchContentRegistry.Focus.active.id {
                notchViewModel.hideTemporaryNotification()
            }
            notchViewModel.send(.hideLiveActivity(id: NotchContentRegistry.Focus.active.id))
            guard settingsViewModel.isTemporaryActivityEnabled(.focusOff) else { return }
            notchViewModel.send(.showTemporaryNotification(FocusOffNotchContent(settingsViewModel: settingsViewModel, focusModeType: modeType), duration: settingsViewModel.temporaryActivityDuration(for: .focusOff))
            )
        }
    }
}
