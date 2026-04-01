import SwiftUI

@MainActor
final class NotchSystemEventsHandler {
    private let notchViewModel: NotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
    }

    func handleNotchSize(_ event: NotchSizeEvent) {
        switch event {
        case .width:
            notchViewModel.send(
                .showTemporaryNotification(
                    NotchSizeWidthNotchContent(generalSettingsViewModel: generalSettingsViewModel),
                    duration: 2
                )
            )

        case .height:
            notchViewModel.send(
                .showTemporaryNotification(
                    NotchSizeHeightNotchContent(generalSettingsViewModel: generalSettingsViewModel),
                    duration: 2
                )
            )
        }
    }
}
