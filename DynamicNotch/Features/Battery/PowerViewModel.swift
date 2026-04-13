import Foundation
import Combine

@MainActor
final class PowerViewModel: ObservableObject {
    @Published var event: PowerEvent?

    private let powerStateProvider: any PowerStateProviding
    private let batterySettings: BatterySettingsStore
    private var previousOnACPower: Bool
    private var previousBatteryLevel: Int
    private var lowPowerThreshold: Int
    private var fullPowerThreshold: Int
    private var cancellables = Set<AnyCancellable>()

    init(
        powerService: any PowerStateProviding,
        batterySettings: BatterySettingsStore
    ) {
        self.powerStateProvider = powerService
        self.batterySettings = batterySettings
        self.previousOnACPower = powerService.onACPower
        self.previousBatteryLevel = powerService.batteryLevel
        self.lowPowerThreshold = batterySettings.lowPowerNotificationThreshold
        self.fullPowerThreshold = batterySettings.fullPowerNotificationThreshold
        setupThresholdBindings()
        setupBindings()
    }

    private func setupThresholdBindings() {
        batterySettings.$lowPowerNotificationThreshold
            .sink { [weak self] value in
                self?.lowPowerThreshold = value
            }
            .store(in: &cancellables)

        batterySettings.$fullPowerNotificationThreshold
            .sink { [weak self] value in
                self?.fullPowerThreshold = value
            }
            .store(in: &cancellables)
    }

    private func setupBindings() {
        powerStateProvider.onPowerStateChange = { [weak self] onACPower, batteryLevel in
            guard let self else { return }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self.handlePowerStateChange(onACPower: onACPower, batteryLevel: batteryLevel)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.handlePowerStateChange(onACPower: onACPower, batteryLevel: batteryLevel)
                }
            }
        }
    }

    private func handlePowerStateChange(onACPower: Bool, batteryLevel: Int) {
        if !previousOnACPower && onACPower {
            event = .charger
        }

        if previousBatteryLevel > lowPowerThreshold && batteryLevel <= lowPowerThreshold {
            event = .lowPower
        }

        if previousBatteryLevel < fullPowerThreshold && batteryLevel >= fullPowerThreshold {
            event = .fullPower
        }

        previousOnACPower = onACPower
        previousBatteryLevel = batteryLevel
    }
}
