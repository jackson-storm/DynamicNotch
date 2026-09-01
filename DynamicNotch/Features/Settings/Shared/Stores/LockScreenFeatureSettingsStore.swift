import Foundation
import Combine

extension LockScreenStyle: StoredSettingValue {}
extension LockScreenWidgetAppearanceStyle: StoredSettingValue {}
extension LockScreenWidgetTintStyle: StoredSettingValue {}
extension LockScreenMediaPanelBackgroundStyle: StoredSettingValue {}

@MainActor
final class LockScreenFeatureSettingsStore: SettingsStoreBase {
    @StoredDefault(key: LockScreenSettings.liveActivityKey, defaultValue: true)
    var isLockScreenLiveActivityEnabled: Bool

    @StoredDefault(key: LockScreenSettings.soundKey, defaultValue: true)
    var isLockScreenSoundEnabled: Bool

    @StoredDefault(key: LockScreenSettings.customLockSoundPathKey, defaultValue: "")
    var customLockSoundPath: String

    @StoredDefault(key: LockScreenSettings.customUnlockSoundPathKey, defaultValue: "")
    var customUnlockSoundPath: String

    @StoredDefault(key: LockScreenSettings.mediaPanelKey, defaultValue: true)
    var isLockScreenMediaPanelEnabled: Bool

    @StoredDefault(key: LockScreenSettings.styleKey, defaultValue: .compact)
    var lockScreenStyle: LockScreenStyle

    @StoredDefault(key: LockScreenSettings.widgetAppearanceStyleKey, defaultValue: .ultraThinMaterial)
    var widgetAppearanceStyle: LockScreenWidgetAppearanceStyle

    @StoredDefault(key: LockScreenSettings.widgetTintStyleKey, defaultValue: .neutral)
    var widgetTintStyle: LockScreenWidgetTintStyle

    @StoredDefault(key: LockScreenSettings.widgetBackgroundBrightnessKey, defaultValue: 1.0)
    var widgetBackgroundBrightness: Double

    @StoredDefault(key: LockScreenSettings.liquidGlassVariantKey, defaultValue: 0)
    var liquidGlassVariant: Int

    @StoredDefault(key: LockScreenSettings.mediaPanelBackgroundStyleKey, defaultValue: .staticArtwork)
    var mediaPanelBackgroundStyle: LockScreenMediaPanelBackgroundStyle

    @StoredDefault(key: LockScreenSettings.lyricsEnabledKey, defaultValue: false)
    var isLockScreenLyricsEnabled: Bool

    @StoredDefault(key: LockScreenSettings.artworkExpandedKey, defaultValue: false)
    var isLockScreenArtworkExpanded: Bool

    @StoredDefault(key: LockScreenSettings.mediaPanelVerticalOffsetKey, defaultValue: 0.0)
    var mediaPanelVerticalOffset: Double

    override init(defaults: UserDefaults) {
        super.init(defaults: defaults)

        let legacyCustomSoundPath = LockScreenSettings.legacyCustomSoundPath(in: defaults) ?? ""
        let storedLockSoundPath = defaults.string(forKey: LockScreenSettings.customLockSoundPathKey)
        let storedUnlockSoundPath = defaults.string(forKey: LockScreenSettings.customUnlockSoundPathKey)

        migrateLegacyCustomSoundIfNeeded(
            legacyCustomSoundPath: legacyCustomSoundPath,
            storedLockSoundPath: storedLockSoundPath,
            storedUnlockSoundPath: storedUnlockSoundPath
        )
    }

    func reset() {
        isLockScreenLiveActivityEnabled = defaultBool(for: LockScreenSettings.liveActivityKey)
        isLockScreenSoundEnabled = defaultBool(for: LockScreenSettings.soundKey)
        customLockSoundPath = defaultString(for: LockScreenSettings.customLockSoundPathKey)
        customUnlockSoundPath = defaultString(for: LockScreenSettings.customUnlockSoundPathKey)
        isLockScreenMediaPanelEnabled = defaultBool(for: LockScreenSettings.mediaPanelKey)
        lockScreenStyle = LockScreenStyle(rawValue: defaultString(for: LockScreenSettings.styleKey)) ?? .compact
        widgetAppearanceStyle = LockScreenWidgetAppearanceStyle(
            rawValue: defaultString(for: LockScreenSettings.widgetAppearanceStyleKey)
        ) ?? .ultraThinMaterial
        widgetTintStyle = LockScreenWidgetTintStyle(
            rawValue: defaultString(for: LockScreenSettings.widgetTintStyleKey)
        ) ?? .neutral
        widgetBackgroundBrightness = defaultDouble(for: LockScreenSettings.widgetBackgroundBrightnessKey)
        liquidGlassVariant = defaultInt(for: LockScreenSettings.liquidGlassVariantKey)
        mediaPanelBackgroundStyle = LockScreenMediaPanelBackgroundStyle(
            rawValue: defaultString(for: LockScreenSettings.mediaPanelBackgroundStyleKey)
        ) ?? .staticArtwork
        isLockScreenLyricsEnabled = defaultBool(for: LockScreenSettings.lyricsEnabledKey)
        isLockScreenArtworkExpanded = defaultBool(for: LockScreenSettings.artworkExpandedKey)
        mediaPanelVerticalOffset = defaultDouble(for: LockScreenSettings.mediaPanelVerticalOffsetKey)
    }

    private func migrateLegacyCustomSoundIfNeeded(
        legacyCustomSoundPath: String,
        storedLockSoundPath: String?,
        storedUnlockSoundPath: String?
    ) {
        guard legacyCustomSoundPath.isEmpty == false else {
            return
        }

        if storedLockSoundPath == nil {
            persist(customLockSoundPath, for: LockScreenSettings.customLockSoundPathKey)
        }

        if storedUnlockSoundPath == nil {
            persist(customUnlockSoundPath, for: LockScreenSettings.customUnlockSoundPathKey)
        }

        persist("", for: LockScreenSettings.customSoundPathKey)
    }
}
