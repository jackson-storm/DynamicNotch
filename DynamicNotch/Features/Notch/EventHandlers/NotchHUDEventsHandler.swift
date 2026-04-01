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
        let duration = generalSettingsViewModel.resolvedTemporaryActivityDuration(2)

        switch event {
        case .display(let level):
            guard generalSettingsViewModel.isHUDEnabled(.brightness) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(
                        kind: .brightness,
                        level: level,
                        style: generalSettingsViewModel.hudStyle,
                        usesColoredLevelTint: generalSettingsViewModel.isHUDColoredLevelEnabled,
                        usesColoredLevelStroke: generalSettingsViewModel.isHUDColoredLevelStrokeEnabled
                    ),
                    duration: duration
                )
            )

        case .keyboard(let level):
            guard generalSettingsViewModel.isHUDEnabled(.keyboard) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(
                        kind: .keyboard,
                        level: level,
                        style: generalSettingsViewModel.hudStyle,
                        usesColoredLevelTint: generalSettingsViewModel.isHUDColoredLevelEnabled,
                        usesColoredLevelStroke: generalSettingsViewModel.isHUDColoredLevelStrokeEnabled
                    ),
                    duration: duration
                )
            )

        case .volume(let level):
            guard generalSettingsViewModel.isHUDEnabled(.volume) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(
                        kind: .volume,
                        level: level,
                        style: generalSettingsViewModel.hudStyle,
                        usesColoredLevelTint: generalSettingsViewModel.isHUDColoredLevelEnabled,
                        usesColoredLevelStroke: generalSettingsViewModel.isHUDColoredLevelStrokeEnabled
                    ),
                    duration: duration
                )
            )
        }
    }
}
