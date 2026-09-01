import SwiftUI
internal import AppKit

@MainActor
final class NotchPowerEventsHandler {
    private let notchViewModel: NotchViewModel
    private let powerService: PowerService
    private let settingsViewModel: SettingsViewModel
    
    init(
        notchViewModel: NotchViewModel,
        powerService: PowerService,
        settingsViewModel: SettingsViewModel,
    ) {
        self.notchViewModel = notchViewModel
        self.powerService = powerService
        self.settingsViewModel = settingsViewModel
    }
    
    func handle(_ event: PowerEvent) {
        playCustomSound(for: event)
        
        switch event {
        case .charger:
            guard settingsViewModel.isTemporaryActivityEnabled(.charger) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    ChargerNotchContent(
                        powerService: powerService,
                        settingsViewModel: settingsViewModel
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .charger)
                )
            )
            
        case .lowPower:
            guard settingsViewModel.isTemporaryActivityEnabled(.lowPower) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    LowPowerNotchContent(
                        powerService: powerService,
                        settingsViewModel: settingsViewModel
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .lowPower)
                )
            )
            
        case .fullPower:
            guard settingsViewModel.isTemporaryActivityEnabled(.fullPower) else { return }
            notchViewModel.send(
                .showTemporaryNotification(
                    FullPowerNotchContent(
                        powerService: powerService,
                        settingsViewModel: settingsViewModel
                    ),
                    duration: settingsViewModel.temporaryActivityDuration(for: .fullPower)
                )
            )
        }
    }
    
    private func playCustomSound(for event: PowerEvent) {
        switch event {
        case .lowPower:
            if settingsViewModel.battery.lowBatterySound {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    NSSound(named: "LowBatterySound")?.play()
                }
            }
        case .fullPower:
            if settingsViewModel.battery.fullBatterySound {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSSound(named: "Glass")?.play()
                }
            }
        case .charger:
            break
        }
    }
}
