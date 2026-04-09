import Foundation
import Combine

@MainActor
final class BatterySettingsStore: SettingsStoreBase {
    static let lowPowerThresholdRange: ClosedRange<Int> = 5...50
    static let fullPowerThresholdRange: ClosedRange<Int> = 50...100

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

    @Published var lowPowerNotificationThreshold: Int {
        didSet {
            let clampedValue = Self.clampLowPowerThreshold(lowPowerNotificationThreshold)
            if clampedValue != lowPowerNotificationThreshold {
                lowPowerNotificationThreshold = clampedValue
                return
            }

            persist(lowPowerNotificationThreshold, for: GeneralSettingsStorage.Keys.lowPowerNotificationThreshold)
        }
    }

    @Published var fullPowerNotificationThreshold: Int {
        didSet {
            let clampedValue = Self.clampFullPowerThreshold(fullPowerNotificationThreshold)
            if clampedValue != fullPowerNotificationThreshold {
                fullPowerNotificationThreshold = clampedValue
                return
            }

            persist(fullPowerNotificationThreshold, for: GeneralSettingsStorage.Keys.fullPowerNotificationThreshold)
        }
    }

    @Published var lowPowerStyle: BatteryNotificationStyle {
        didSet {
            persist(lowPowerStyle.rawValue, for: GeneralSettingsStorage.Keys.lowPowerNotificationStyle)
        }
    }

    @Published var fullPowerStyle: BatteryNotificationStyle {
        didSet {
            persist(fullPowerStyle.rawValue, for: GeneralSettingsStorage.Keys.fullPowerNotificationStyle)
        }
    }

    override init(defaults: UserDefaults) {
        self.isChargerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled)
        self.isLowPowerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        self.isFullPowerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        let storedLowPowerThreshold = defaults.object(forKey: GeneralSettingsStorage.Keys.lowPowerNotificationThreshold) as? Int
        let storedFullPowerThreshold = defaults.object(forKey: GeneralSettingsStorage.Keys.fullPowerNotificationThreshold) as? Int
        self.lowPowerNotificationThreshold = Self.clampLowPowerThreshold(
            storedLowPowerThreshold ??
            (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.lowPowerNotificationThreshold] as? Int ?? 20)
        )
        self.fullPowerNotificationThreshold = Self.clampFullPowerThreshold(
            storedFullPowerThreshold ??
            (GeneralSettingsStorage.defaultValues[GeneralSettingsStorage.Keys.fullPowerNotificationThreshold] as? Int ?? 100)
        )
        self.lowPowerStyle = BatteryNotificationStyle(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.lowPowerNotificationStyle) ??
            BatteryNotificationStyle.standard.rawValue
        ) ?? .standard
        self.fullPowerStyle = BatteryNotificationStyle(
            rawValue: defaults.string(forKey: GeneralSettingsStorage.Keys.fullPowerNotificationStyle) ??
            BatteryNotificationStyle.standard.rawValue
        ) ?? .standard
        super.init(defaults: defaults)
    }

    func reset() {
        isChargerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled)
        isLowPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        isFullPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        lowPowerNotificationThreshold = Self.clampLowPowerThreshold(defaultInt(for: GeneralSettingsStorage.Keys.lowPowerNotificationThreshold))
        fullPowerNotificationThreshold = Self.clampFullPowerThreshold(defaultInt(for: GeneralSettingsStorage.Keys.fullPowerNotificationThreshold))
        lowPowerStyle = BatteryNotificationStyle(rawValue: defaultString(for: GeneralSettingsStorage.Keys.lowPowerNotificationStyle)) ?? .standard
        fullPowerStyle = BatteryNotificationStyle(rawValue: defaultString(for: GeneralSettingsStorage.Keys.fullPowerNotificationStyle)) ?? .standard
    }

    private static func clampLowPowerThreshold(_ value: Int) -> Int {
        min(max(value, lowPowerThresholdRange.lowerBound), lowPowerThresholdRange.upperBound)
    }

    private static func clampFullPowerThreshold(_ value: Int) -> Int {
        min(max(value, fullPowerThresholdRange.lowerBound), fullPowerThresholdRange.upperBound)
    }
}
