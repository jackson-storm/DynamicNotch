import Combine
import Foundation

@MainActor
final class NotificationsSettingsStore: SettingsStoreBase {
    @Published var isEnabled: Bool {
        didSet { persist(isEnabled, for: GeneralSettingsStorage.Keys.notificationsEnabled) }
    }

    override init(defaults: UserDefaults = .standard) {
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)
        self.isEnabled = (defaults.object(forKey: GeneralSettingsStorage.Keys.notificationsEnabled) as? Bool)
            ?? true
        super.init(defaults: defaults)
    }
}
