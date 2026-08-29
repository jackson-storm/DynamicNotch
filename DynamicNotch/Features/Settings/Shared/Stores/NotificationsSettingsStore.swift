import Combine
import Foundation

@MainActor
final class NotificationsSettingsStore: SettingsStoreBase {
    @Published var isAppleMailNotificationsEnabled: Bool {
        didSet {
            persist(
                isAppleMailNotificationsEnabled,
                for: GeneralSettingsStorage.Keys.appleMailNotificationsEnabled
            )
        }
    }
    
    @Published var appleMailNotificationDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(appleMailNotificationDuration)
            if clampedValue != appleMailNotificationDuration {
                appleMailNotificationDuration = clampedValue
                return
            }

            persist(
                appleMailNotificationDuration,
                for: GeneralSettingsStorage.Keys.appleMailNotificationDuration
            )
        }
    }

    var isAppleMailNotificationsPermissionPending: Bool {
        didSet {
            persist(
                isAppleMailNotificationsPermissionPending,
                for: GeneralSettingsStorage.Keys.appleMailNotificationsPermissionPending
            )
        }
    }

    @Published var isAppleMessagesNotificationsEnabled: Bool {
        didSet {
            persist(
                isAppleMessagesNotificationsEnabled,
                for: GeneralSettingsStorage.Keys.appleMessagesNotificationsEnabled
            )
        }
    }

    @Published var appleMessagesNotificationDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(appleMessagesNotificationDuration)
            if clampedValue != appleMessagesNotificationDuration {
                appleMessagesNotificationDuration = clampedValue
                return
            }

            persist(
                appleMessagesNotificationDuration,
                for: GeneralSettingsStorage.Keys.appleMessagesNotificationDuration
            )
        }
    }

    var isAppleMessagesNotificationsPermissionPending: Bool {
        didSet {
            persist(
                isAppleMessagesNotificationsPermissionPending,
                for: GeneralSettingsStorage.Keys.appleMessagesNotificationsPermissionPending
            )
        }
    }

    @Published var isExternalDrivesNotificationsEnabled: Bool {
        didSet {
            persist(
                isExternalDrivesNotificationsEnabled,
                for: GeneralSettingsStorage.Keys.externalDrivesNotificationsEnabled
            )
        }
    }

    @Published var externalDrivesNotificationDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(externalDrivesNotificationDuration)
            if clampedValue != externalDrivesNotificationDuration {
                externalDrivesNotificationDuration = clampedValue
                return
            }

            persist(
                externalDrivesNotificationDuration,
                for: GeneralSettingsStorage.Keys.externalDrivesNotificationDuration
            )
        }
    }

    @Published var isExternalDrivesIncludeDiskImagesEnabled: Bool {
        didSet {
            persist(
                isExternalDrivesIncludeDiskImagesEnabled,
                for: GeneralSettingsStorage.Keys.externalDrivesIncludeDiskImages
            )
        }
    }

    @Published var isExternalDrivesShowEjectedEnabled: Bool {
        didSet {
            persist(
                isExternalDrivesShowEjectedEnabled,
                for: GeneralSettingsStorage.Keys.externalDrivesShowEjected
            )
        }
    }

    override init(defaults: UserDefaults) {
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)

        self.isAppleMailNotificationsEnabled = defaults.object(
            forKey: GeneralSettingsStorage.Keys.appleMailNotificationsEnabled
        ) as? Bool ?? false

        if let storedDuration = defaults.object(forKey: GeneralSettingsStorage.Keys.appleMailNotificationDuration) as? Int {
            self.appleMailNotificationDuration = Self.clampTemporaryActivityDuration(storedDuration)
        } else {
            self.appleMailNotificationDuration = Self.defaultTemporaryActivityDuration(
                for: GeneralSettingsStorage.Keys.appleMailNotificationDuration
            )
        }
        
        self.isAppleMailNotificationsPermissionPending = defaults.object(
            forKey: GeneralSettingsStorage.Keys.appleMailNotificationsPermissionPending
        ) as? Bool ?? false

        self.isAppleMessagesNotificationsEnabled = defaults.object(
            forKey: GeneralSettingsStorage.Keys.appleMessagesNotificationsEnabled
        ) as? Bool ?? false

        if let storedDuration = defaults.object(forKey: GeneralSettingsStorage.Keys.appleMessagesNotificationDuration) as? Int {
            self.appleMessagesNotificationDuration = Self.clampTemporaryActivityDuration(storedDuration)
        } else {
            self.appleMessagesNotificationDuration = Self.defaultTemporaryActivityDuration(
                for: GeneralSettingsStorage.Keys.appleMessagesNotificationDuration
            )
        }

        self.isAppleMessagesNotificationsPermissionPending = defaults.object(
            forKey: GeneralSettingsStorage.Keys.appleMessagesNotificationsPermissionPending
        ) as? Bool ?? false

        self.isExternalDrivesNotificationsEnabled = defaults.object(
            forKey: GeneralSettingsStorage.Keys.externalDrivesNotificationsEnabled
        ) as? Bool ?? true

        if let storedDuration = defaults.object(forKey: GeneralSettingsStorage.Keys.externalDrivesNotificationDuration) as? Int {
            self.externalDrivesNotificationDuration = Self.clampTemporaryActivityDuration(storedDuration)
        } else {
            self.externalDrivesNotificationDuration = Self.defaultTemporaryActivityDuration(
                for: GeneralSettingsStorage.Keys.externalDrivesNotificationDuration
            )
        }

        self.isExternalDrivesIncludeDiskImagesEnabled = defaults.object(
            forKey: GeneralSettingsStorage.Keys.externalDrivesIncludeDiskImages
        ) as? Bool ?? true

        self.isExternalDrivesShowEjectedEnabled = defaults.object(
            forKey: GeneralSettingsStorage.Keys.externalDrivesShowEjected
        ) as? Bool ?? true

        super.init(defaults: defaults)
    }

    func reset() {
        isAppleMailNotificationsEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.appleMailNotificationsEnabled
        )

        appleMailNotificationDuration = Self.defaultTemporaryActivityDuration(
            for: GeneralSettingsStorage.Keys.appleMailNotificationDuration
        )
        
        isAppleMailNotificationsPermissionPending = false

        isAppleMessagesNotificationsEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.appleMessagesNotificationsEnabled
        )

        appleMessagesNotificationDuration = Self.defaultTemporaryActivityDuration(
            for: GeneralSettingsStorage.Keys.appleMessagesNotificationDuration
        )

        isAppleMessagesNotificationsPermissionPending = false

        isExternalDrivesNotificationsEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.externalDrivesNotificationsEnabled
        )

        externalDrivesNotificationDuration = Self.defaultTemporaryActivityDuration(
            for: GeneralSettingsStorage.Keys.externalDrivesNotificationDuration
        )

        isExternalDrivesIncludeDiskImagesEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.externalDrivesIncludeDiskImages
        )

        isExternalDrivesShowEjectedEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.externalDrivesShowEjected
        )
    }
}
