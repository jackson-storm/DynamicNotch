import Foundation
import Combine

@MainActor
final class BatterySettingsStore: SettingsStoreBase {
    @Published var isChargerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isChargerTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled)
        }
    }

    @Published var isLowPowerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isLowPowerTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        }
    }

    @Published var isFullPowerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isFullPowerTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        }
    }

    @Published var isBatteryDefaultStrokeEnabled: Bool {
        didSet {
            persist(isBatteryDefaultStrokeEnabled, for: GeneralSettingsStorage.Keys.batteryDefaultStrokeEnabled)
        }
    }

    override init(defaults: UserDefaults) {
        self.isChargerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled)
        self.isLowPowerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        self.isFullPowerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        self.isBatteryDefaultStrokeEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.batteryDefaultStrokeEnabled)
        super.init(defaults: defaults)
    }

    func reset() {
        isChargerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled)
        isLowPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        isFullPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        isBatteryDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.batteryDefaultStrokeEnabled)
    }
}
