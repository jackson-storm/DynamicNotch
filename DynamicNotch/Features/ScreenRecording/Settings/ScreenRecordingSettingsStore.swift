import Combine
import Foundation

extension ScreenRecordingStyle: StoredSettingValue {}

@MainActor
final class ScreenRecordingSettingsStore: SettingsStoreBase {
    @StoredDefault(key: GeneralSettingsStorage.Keys.screenRecordingLiveActivityEnabled, defaultValue: true)
    var isScreenRecordingLiveActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.screenRecordingStyle, defaultValue: .detailed)
    var screenRecordingStyle: ScreenRecordingStyle

    @StoredDefault(key: GeneralSettingsStorage.Keys.screenshotActivityEnabled, defaultValue: true)
    var isScreenshotActivityEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.screenshotDisableSystemThumbnail, defaultValue: true)
    var isScreenshotDisableSystemThumbnailEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.screenshotAutoHideEnabled, defaultValue: true)
    var isScreenshotAutoHideEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.screenshotTemporaryActivityDuration,
        defaultValue: 4,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var screenshotTemporaryActivityDuration: Int

    override init(defaults: UserDefaults) {
        super.init(defaults: defaults)
    }

    func reset() {
        isScreenRecordingLiveActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.screenRecordingLiveActivityEnabled)
        screenRecordingStyle = .detailed
        isScreenshotActivityEnabled = defaultBool(for: GeneralSettingsStorage.Keys.screenshotActivityEnabled)
        isScreenshotDisableSystemThumbnailEnabled = defaultBool(for: GeneralSettingsStorage.Keys.screenshotDisableSystemThumbnail)
        isScreenshotAutoHideEnabled = defaultBool(for: GeneralSettingsStorage.Keys.screenshotAutoHideEnabled)
        screenshotTemporaryActivityDuration = defaultInt(for: GeneralSettingsStorage.Keys.screenshotTemporaryActivityDuration)
    }
}
