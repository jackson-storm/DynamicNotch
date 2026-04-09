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
        guard settingsViewModel.isTemporaryActivityEnabled(.notchSize) else { return }
        let duration = settingsViewModel.temporaryActivityDuration(for: .notchSize)

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
