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

    @Published var chargerTemporaryActivityDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(chargerTemporaryActivityDuration)
            if clampedValue != chargerTemporaryActivityDuration {
                chargerTemporaryActivityDuration = clampedValue
                return
            }

            persist(chargerTemporaryActivityDuration, for: GeneralSettingsStorage.Keys.chargerTemporaryActivityDuration)
        }
    }

    @Published var isLowPowerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isLowPowerTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        }
    }

    @Published var lowPowerTemporaryActivityDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(lowPowerTemporaryActivityDuration)
            if clampedValue != lowPowerTemporaryActivityDuration {
                lowPowerTemporaryActivityDuration = clampedValue
                return
            }

            persist(lowPowerTemporaryActivityDuration, for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityDuration)
        }
    }

    @Published var isFullPowerTemporaryActivityEnabled: Bool {
        didSet {
            persist(isFullPowerTemporaryActivityEnabled, for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        }
    }

    @Published var fullPowerTemporaryActivityDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(fullPowerTemporaryActivityDuration)
            if clampedValue != fullPowerTemporaryActivityDuration {
                fullPowerTemporaryActivityDuration = clampedValue
                return
            }

            persist(fullPowerTemporaryActivityDuration, for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityDuration)
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
        self.chargerTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.chargerTemporaryActivityDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.chargerTemporaryActivityDuration)
        )
        self.isLowPowerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        self.lowPowerTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityDuration)
        )
        self.isFullPowerTemporaryActivityEnabled = defaults.bool(forKey: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        self.fullPowerTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaults.object(forKey: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityDuration) as? Int ??
            Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityDuration)
        )
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
        chargerTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.chargerTemporaryActivityDuration)
        )
        isLowPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        lowPowerTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityDuration)
        )
        isFullPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        fullPowerTemporaryActivityDuration = Self.clampTemporaryActivityDuration(
            defaultInt(for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityDuration)
        )
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
