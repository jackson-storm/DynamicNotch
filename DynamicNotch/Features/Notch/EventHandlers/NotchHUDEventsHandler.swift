import SwiftUI

@MainActor
final class NotchHUDEventsHandler {
    private let notchViewModel: NotchViewModel
    private let settingsViewModel: SettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        settingsViewModel: SettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.settingsViewModel = settingsViewModel
    }

    func handle(_ event: HudEvent) {
        switch event {
        case .display(let level):
            guard settingsViewModel.isHUDEnabled(.brightness) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(
                        kind: .brightness,
                        level: level,
                        style: settingsViewModel.hudStyle,
                        indicatorStyle: settingsViewModel.hudIndicatorStyle,
                        usesColoredLevelTint: settingsViewModel.isHUDColoredLevelEnabled,
                        usesColoredLevelStroke: settingsViewModel.isHUDColoredLevelStrokeEnabled
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .brightness)
                )
            )

        case .keyboard(let level):
            guard settingsViewModel.isHUDEnabled(.keyboard) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(
                        kind: .keyboard,
                        level: level,
                        style: settingsViewModel.hudStyle,
                        indicatorStyle: settingsViewModel.hudIndicatorStyle,
                        usesColoredLevelTint: settingsViewModel.isHUDColoredLevelEnabled,
                        usesColoredLevelStroke: settingsViewModel.isHUDColoredLevelStrokeEnabled
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .keyboard)
                )
            )

        case .volume(let level):
            guard settingsViewModel.isHUDEnabled(.volume) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    HudNotchContent(
                        kind: .volume,
                        level: level,
                        style: settingsViewModel.hudStyle,
                        indicatorStyle: settingsViewModel.hudIndicatorStyle,
                        usesColoredLevelTint: settingsViewModel.isHUDColoredLevelEnabled,
                        usesColoredLevelStroke: settingsViewModel.isHUDColoredLevelStrokeEnabled
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .volume)
                )
            )
        }
    }
}
