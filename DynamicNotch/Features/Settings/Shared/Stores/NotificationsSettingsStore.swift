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

    override init(defaults: UserDefaults) {
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)

        self.isAppleMailNotificationsEnabled = defaults.object(
            forKey: GeneralSettingsStorage.Keys.appleMailNotificationsEnabled
        ) as? Bool ?? false

        super.init(defaults: defaults)
    }

    func reset() {
        isAppleMailNotificationsEnabled = defaultBool(
            for: GeneralSettingsStorage.Keys.appleMailNotificationsEnabled
        )
    }
}
