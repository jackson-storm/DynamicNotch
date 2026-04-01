import SwiftUI

@MainActor
final class NotchHUDEventsHandler {
    private let notchViewModel: NotchViewModel
    private let generalSettingsViewModel: GeneralSettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
    }

    func handle(_ event: HudEvent) {
        switch event {
        case .display(let level):
            guard generalSettingsViewModel.isHUDEnabled(.brightness) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(kind: .brightness, level: level),
                    duration: 2
                )
            )

        case .keyboard(let level):
            guard generalSettingsViewModel.isHUDEnabled(.keyboard) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(kind: .keyboard, level: level),
                    duration: 2
                )
            )

        case .volume(let level):
            guard generalSettingsViewModel.isHUDEnabled(.volume) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(kind: .volume, level: level),
                    duration: 2
                )
            )
        }
    }
}
