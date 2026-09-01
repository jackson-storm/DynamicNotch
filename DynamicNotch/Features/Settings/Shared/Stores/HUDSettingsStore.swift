import Foundation
import Combine

extension HudStyle: StoredSettingValue {}
extension HudIndicatorStyle: StoredSettingValue {}
extension HudIndicatorTintStyle: StoredSettingValue {}

@MainActor
final class HUDSettingsStore: SettingsStoreBase {
    @StoredDefault(key: GeneralSettingsStorage.Keys.brightnessHUDEnabled, defaultValue: true)
    var isBrightnessHUDEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.brightnessHUDDuration,
        defaultValue: 2,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var brightnessHUDDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.keyboardHUDEnabled, defaultValue: true)
    var isKeyboardHUDEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.keyboardHUDDuration,
        defaultValue: 2,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var keyboardHUDDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.volumeHUDEnabled, defaultValue: true)
    var isVolumeHUDEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.volumeFeedbackSoundEnabled, defaultValue: true)
    var isVolumeFeedbackSoundEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.volumeHUDDuration,
        defaultValue: 2,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var volumeHUDDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.hudStyle, defaultValue: .compact)
    var hudStyle: HudStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.hudIndicatorStyle, defaultValue: .bar)
    var indicatorStyle: HudIndicatorStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.hudIndicatorTintStyle, defaultValue: .levelColor)
    var indicatorTintStyle: HudIndicatorTintStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.hudIndicatorGlowEnabled, defaultValue: true)
    var isIndicatorGlowEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.hudColoredStrokeEnabled, defaultValue: false)
    var isColoredLevelStrokeEnabled: Bool

    override init(defaults: UserDefaults) {
        if defaults.string(forKey: GeneralSettingsStorage.Keys.hudIndicatorTintStyle) == nil,
           let legacyColoredLevel = defaults.object(forKey: GeneralSettingsStorage.Keys.hudColoredLevelEnabled) as? Bool {
            defaults.set(
                (legacyColoredLevel ? HudIndicatorTintStyle.levelColor : .plainWhite).rawValue,
                forKey: GeneralSettingsStorage.Keys.hudIndicatorTintStyle
            )
        }

        super.init(defaults: defaults)
    }

    func reset() {
        isBrightnessHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.brightnessHUDEnabled)
        brightnessHUDDuration = defaultInt(for: GeneralSettingsStorage.Keys.brightnessHUDDuration)
        isKeyboardHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.keyboardHUDEnabled)
        keyboardHUDDuration = defaultInt(for: GeneralSettingsStorage.Keys.keyboardHUDDuration)
        isVolumeHUDEnabled = defaultBool(for: GeneralSettingsStorage.Keys.volumeHUDEnabled)
        isVolumeFeedbackSoundEnabled = defaultBool(for: GeneralSettingsStorage.Keys.volumeFeedbackSoundEnabled)
        volumeHUDDuration = defaultInt(for: GeneralSettingsStorage.Keys.volumeHUDDuration)
        hudStyle = .compact
        indicatorStyle = .bar
        indicatorTintStyle = .levelColor
        isIndicatorGlowEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hudIndicatorGlowEnabled)
        isColoredLevelStrokeEnabled = defaultBool(for: GeneralSettingsStorage.Keys.hudColoredStrokeEnabled)
    }
}
