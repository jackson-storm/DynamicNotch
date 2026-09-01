import Foundation
import Combine

extension BatteryNotificationStyle: StoredSettingValue {}

@MainActor
final class BatterySettingsStore: SettingsStoreBase {
    static let lowPowerThresholdRange: ClosedRange<Int> = 5...50
    static let fullPowerThresholdRange: ClosedRange<Int> = 50...100
    private static let legacyBatteryDefaultStrokeKey = "settings.battery.defaultStroke"

    @StoredDefault(key: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled, defaultValue: true)
    var isChargerTemporaryActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.chargerTemporaryActivityDuration,
        defaultValue: 4,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var chargerTemporaryActivityDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled, defaultValue: true)
    var isLowPowerTemporaryActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityDuration,
        defaultValue: 4,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var lowPowerTemporaryActivityDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled, defaultValue: true)
    var isFullPowerTemporaryActivityEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityDuration,
        defaultValue: 4,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var fullPowerTemporaryActivityDuration: Int

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.lowPowerNotificationThreshold,
        defaultValue: 20,
        transform: BatterySettingsStore.clampLowPowerThreshold
    )
    var lowPowerNotificationThreshold: Int

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.fullPowerNotificationThreshold,
        defaultValue: 100,
        transform: BatterySettingsStore.clampFullPowerThreshold
    )
    var fullPowerNotificationThreshold: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.lowPowerNotificationStyle, defaultValue: .standard)
    var lowPowerStyle: BatteryNotificationStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.fullPowerNotificationStyle, defaultValue: .standard)
    var fullPowerStyle: BatteryNotificationStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.fullBatterySound, defaultValue: true)
    var fullBatterySound: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.lowBatterySound, defaultValue: true)
    var lowBatterySound: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.lowPowerDefaultStrokeEnabled, defaultValue: false)
    var isLowPowerDefaultStrokeEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.fullPowerDefaultStrokeEnabled, defaultValue: false)
    var isFullPowerDefaultStrokeEnabled: Bool

    override init(defaults: UserDefaults) {
        Self.migrateLegacyDefaultStrokeIfNeeded(defaults: defaults)
        Self.migrateCorruptedFullPowerStyleIfNeeded(defaults: defaults)
        super.init(defaults: defaults)
    }

    func reset() {
        isChargerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.chargerTemporaryActivityEnabled)
        lowBatterySound = defaultBool(for: GeneralSettingsStorage.Keys.lowBatterySound)
        fullBatterySound = defaultBool(for: GeneralSettingsStorage.Keys.fullBatterySound)
        chargerTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.chargerTemporaryActivityDuration)
        isLowPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityEnabled)
        lowPowerTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.lowPowerTemporaryActivityDuration)
        isFullPowerTemporaryActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityEnabled)
        fullPowerTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.fullPowerTemporaryActivityDuration)
        lowPowerNotificationThreshold = 20
        fullPowerNotificationThreshold = 100
        lowPowerStyle = .standard
        fullPowerStyle = .standard
        isLowPowerDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.lowPowerDefaultStrokeEnabled)
        isFullPowerDefaultStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.fullPowerDefaultStrokeEnabled)
    }

    static func clampLowPowerThreshold(_ value: Int) -> Int {
        min(max(value, lowPowerThresholdRange.lowerBound), lowPowerThresholdRange.upperBound)
    }

    static func clampFullPowerThreshold(_ value: Int) -> Int {
        min(max(value, fullPowerThresholdRange.lowerBound), fullPowerThresholdRange.upperBound)
    }

    private static func migrateLegacyDefaultStrokeIfNeeded(defaults: UserDefaults) {
        guard let legacyValue = defaults.object(forKey: legacyBatteryDefaultStrokeKey) as? Bool else {
            return
        }

        if defaults.object(forKey: GeneralSettingsStorage.Keys.lowPowerDefaultStrokeEnabled) == nil {
            defaults.set(legacyValue, forKey: GeneralSettingsStorage.Keys.lowPowerDefaultStrokeEnabled)
        }

        if defaults.object(forKey: GeneralSettingsStorage.Keys.fullPowerDefaultStrokeEnabled) == nil {
            defaults.set(legacyValue, forKey: GeneralSettingsStorage.Keys.fullPowerDefaultStrokeEnabled)
        }

        defaults.removeObject(forKey: legacyBatteryDefaultStrokeKey)
    }
    
    private static func migrateCorruptedFullPowerStyleIfNeeded(defaults: UserDefaults) {
        let key = GeneralSettingsStorage.Keys.fullPowerNotificationStyle
        if let stored = defaults.object(forKey: key), !(stored is String) {
            defaults.removeObject(forKey: key)
        }
    }
}
