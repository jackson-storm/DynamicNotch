import Foundation
import Combine

enum PowerEvent: Equatable {
    case charger
    case lowPower
    case fullPower
}

final class PowerViewModel: ObservableObject {
    @Published var event: PowerEvent?

    private let powerStateProvider: any PowerStateProviding
    private var previousOnACPower: Bool
    private var previousBatteryLevel: Int

    init(powerService: any PowerStateProviding) {
        self.powerStateProvider = powerService
        self.previousOnACPower = powerService.onACPower
        self.previousBatteryLevel = powerService.batteryLevel
        setupBindings()
    }

    private func setupBindings() {
        powerStateProvider.onPowerStateChange = { [weak self] onACPower, batteryLevel in
            self?.handlePowerStateChange(onACPower: onACPower, batteryLevel: batteryLevel)
        }
    }

    private func handlePowerStateChange(onACPower: Bool, batteryLevel: Int) {
        if !previousOnACPower && onACPower {
            event = .charger
        }

        if previousBatteryLevel > 20 && batteryLevel <= 20 {
            event = .lowPower
        }

        if previousBatteryLevel < 100 && batteryLevel == 100 {
            event = .fullPower
        }

        previousOnACPower = onACPower
        previousBatteryLevel = batteryLevel
    }
}
