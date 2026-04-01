import SwiftUI

@MainActor
final class NotchFocusEventsHandler {
    private let notchViewModel: NotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
    }

    func handle(_ event: FocusEvent) {
        switch event {
        case .FocusOn:
            guard generalSettingsViewModel.isLiveActivityEnabled(.focus) else { return }
            notchViewModel.send(
                .showLiveActivity(
                    FocusOnNotchContent(generalSettingsViewModel: generalSettingsViewModel)
                )
            )

        case .FocusOff:
            notchViewModel.send(.hideLiveActivity(id: "focus.on"))
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.focusOff) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    FocusOffNotchContent(generalSettingsViewModel: generalSettingsViewModel),
                    duration: 3
                )
            )
        }
    }
}
