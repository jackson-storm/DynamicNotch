import Foundation
import Combine

@MainActor
class SettingsStoreBase: ObservableObject {
    fileprivate let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        defaults.register(defaults: GeneralSettingsStorage.defaultValues)
    }

    func persist(_ value: Bool, for key: String) {
        defaults.set(value, forKey: key)
    }

    func persist(_ value: Int, for key: String) {
        defaults.set(value, forKey: key)
    }

    func persist(_ value: Double, for key: String) {
        defaults.set(value, forKey: key)
    }

    func persist(_ value: String, for key: String) {
        defaults.set(value, forKey: key)
    }

    func defaultBool(for key: String) -> Bool {
        (GeneralSettingsStorage.defaultValues[key] as? Bool) ?? false
    }

    func defaultInt(for key: String) -> Int {
        (GeneralSettingsStorage.defaultValues[key] as? Int) ?? 0
    }

    func defaultDouble(for key: String) -> Double {
        (GeneralSettingsStorage.defaultValues[key] as? Double) ?? 0
    }

    func defaultString(for key: String) -> String {
        (GeneralSettingsStorage.defaultValues[key] as? String) ?? ""
    }
}
