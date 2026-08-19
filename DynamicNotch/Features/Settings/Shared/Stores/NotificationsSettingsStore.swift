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
    }
}
