import Combine
import Foundation

@MainActor
final class NotificationsSettingsStore: SettingsStoreBase {
    @StoredDefault(key: GeneralSettingsStorage.Keys.appleMailNotificationsEnabled, defaultValue: false)
    var isAppleMailNotificationsEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.appleMailNotificationDuration,
        defaultValue: 5,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var appleMailNotificationDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.appleMailNotificationsPermissionPending, defaultValue: false)
    var isAppleMailNotificationsPermissionPending: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.messagesNotificationsEnabled, defaultValue: false)
    var isMessagesNotificationsEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.messagesNotificationDuration,
        defaultValue: 5,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
    )
    var messagesNotificationDuration: Int

    @StoredDefault(key: GeneralSettingsStorage.Keys.messagesNotificationsPermissionPending, defaultValue: false)
    var isMessagesNotificationsPermissionPending: Bool

    @StoredDefault(key: GeneralSettingsStorage.Keys.externalDrivesNotificationsEnabled, defaultValue: true)
    var isExternalDrivesNotificationsEnabled: Bool

    @StoredDefault(
        key: GeneralSettingsStorage.Keys.externalDrivesNotificationDuration,
        defaultValue: 5,
        transform: SettingsStoreBase.clampTemporaryActivityDuration
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
        isAppleMailNotificationsEnabled = defaultBool(for: GeneralSettingsStorage.Keys.appleMailNotificationsEnabled)
        appleMailNotificationDuration = Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.appleMailNotificationDuration)
        isAppleMailNotificationsPermissionPending = false
        isMessagesNotificationsEnabled = defaultBool(for: GeneralSettingsStorage.Keys.messagesNotificationsEnabled)
        messagesNotificationDuration = Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.messagesNotificationDuration)
        isMessagesNotificationsPermissionPending = false
        isExternalDrivesNotificationsEnabled = defaultBool(for: GeneralSettingsStorage.Keys.externalDrivesNotificationsEnabled)
        externalDrivesNotificationDuration = Self.defaultTemporaryActivityDuration(for: GeneralSettingsStorage.Keys.externalDrivesNotificationDuration)
        isExternalDrivesIncludeDiskImagesEnabled = defaultBool(for: GeneralSettingsStorage.Keys.externalDrivesIncludeDiskImages)
        isExternalDrivesShowEjectedEnabled = defaultBool(for: GeneralSettingsStorage.Keys.externalDrivesShowEjected)
    }
}
