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

    @Published var isMessagesNotificationsEnabled: Bool {
        didSet {
            persist(
                isMessagesNotificationsEnabled,
                for: GeneralSettingsStorage.Keys.messagesNotificationsEnabled
            )
        }
    }

    @Published var messagesNotificationDuration: Int {
        didSet {
            let clampedValue = Self.clampTemporaryActivityDuration(messagesNotificationDuration)
            if clampedValue != messagesNotificationDuration {
                messagesNotificationDuration = clampedValue
                return
            }

            persist(
                messagesNotificationDuration,
                for: GeneralSettingsStorage.Keys.messagesNotificationDuration
            )
        }
    }

    var isMessagesNotificationsPermissionPending: Bool {
        didSet {
            persist(
                isMessagesNotificationsPermissionPending,
                for: GeneralSettingsStorage.Keys.messagesNotificationsPermissionPending
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

        self.isMessagesNotificationsEnabled = defaults.object(
            forKey: GeneralSettingsStorage.Keys.messagesNotificationsEnabled
        ) as? Bool ?? false

        if let storedDuration = defaults.object(forKey: GeneralSettingsStorage.Keys.messagesNotificationDuration) as? Int {
            self.messagesNotificationDuration = Self.clampTemporaryActivityDuration(storedDuration)
        } else {
            self.messagesNotificationDuration = Self.defaultTemporaryActivityDuration(
                for: GeneralSettingsStorage.Keys.messagesNotificationDuration
            )
        }

        self.isMessagesNotificationsPermissionPending = defaults.object(
            forKey: GeneralSettingsStorage.Keys.messagesNotificationsPermissionPending
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

        isMessagesNotificationsEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.messagesNotificationsEnabled
        )

        messagesNotificationDuration = Self.defaultTemporaryActivityDuration(
            for: GeneralSettingsStorage.Keys.messagesNotificationDuration
        )

        isMessagesNotificationsPermissionPending = false

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
