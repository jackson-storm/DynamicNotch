import SwiftUI

@MainActor
final class NotchSystemEventsHandler {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
    }

    func handleNotchSize(_ event: NotchSizeEvent) {
        let duration = settingsViewModel.resolvedTemporaryActivityDuration(2)

        switch event {
        case .width:
            notchViewModel.send(
                .showTemporaryNotification(
                    NotchSizeWidthNotchContent(settingsViewModel: settingsViewModel),
                    duration: duration
                )
            )

        case .height:
            notchViewModel.send(
                .showTemporaryNotification(
                    NotchSizeHeightNotchContent(settingsViewModel: settingsViewModel),
                    duration: duration
                )
            )
        }
    }
}
