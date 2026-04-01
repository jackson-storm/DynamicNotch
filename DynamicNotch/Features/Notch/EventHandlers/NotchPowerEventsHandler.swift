import SwiftUI

@MainActor
final class NotchPowerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let powerService: PowerService
    private let generalSettingsViewModel: GeneralSettingsViewModel

    init(
        notchViewModel: NotchViewModel,
        powerService: PowerService,
        generalSettingsViewModel: GeneralSettingsViewModel
    ) {
        self.notchViewModel = notchViewModel
        self.powerService = powerService
        self.generalSettingsViewModel = generalSettingsViewModel
    }

    func handle(_ event: PowerEvent) {
        switch event {
        case .charger:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.charger) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    ChargerNotchContent(
                        powerService: powerService,
                        generalSettingsViewModel: generalSettingsViewModel
                    ),
                    duration: 4
                )
            )

        case .lowPower:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.lowPower) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    LowPowerNotchContent(
                        powerService: powerService,
                        generalSettingsViewModel: generalSettingsViewModel
                    ),
                    duration: 4
                )
            )

        case .fullPower:
            guard generalSettingsViewModel.isTemporaryActivityEnabled(.fullPower) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    FullPowerNotchContent(
                        powerService: powerService,
                        generalSettingsViewModel: generalSettingsViewModel
                    ),
                    duration: 4
                )
            )
        }
    }
}
