import Combine
import Foundation

@MainActor
final class NotificationsSettingsStore: SettingsStoreBase {
    @StoredDefault(key: GeneralSettingsStorage.Keys.externalDrivesNotificationsEnabled, defaultValue: true)
    var isExternalDrivesNotificationsEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.externalDrivesNotificationDuration,
        defaultValue: 8,
        transform: SettingsStoreBase.clampNotificationDuration
    )
    var externalDrivesNotificationDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.externalDrivesIncludeDiskImages, defaultValue: true)
    var isExternalDrivesIncludeDiskImagesEnabled: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.externalDrivesShowEjected, defaultValue: true)
    var isExternalDrivesShowEjectedEnabled: Bool

    override init(defaults: UserDefaults) {
        super.init(defaults: defaults)
    }

    func reset() {
        isExternalDrivesNotificationsEnabled = defaultBool(for: GeneralSettingsStorage.Keys.externalDrivesNotificationsEnabled)
        externalDrivesNotificationDuration = Self.defaultNotificationDuration(for: GeneralSettingsStorage.Keys.externalDrivesNotificationDuration)
        isExternalDrivesIncludeDiskImagesEnabled = defaultBool(for: GeneralSettingsStorage.Keys.externalDrivesIncludeDiskImages)
        isExternalDrivesShowEjectedEnabled = defaultBool(for: GeneralSettingsStorage.Keys.externalDrivesShowEjected)
    }
}

