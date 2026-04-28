import Foundation
import Combine

@MainActor
class SettingsStoreBase: ObservableObject {
    class var temporaryActivityDurationRange: ClosedRange<Int> { 1...5 }

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

    func persist(_ value: [String: Int], for key: String) {
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

    class func clampTemporaryActivityDuration(_ value: Int) -> Int {
        min(
            max(value, temporaryActivityDurationRange.lowerBound),
            temporaryActivityDurationRange.upperBound
        )
    }

    class func defaultTemporaryActivityDuration(for key: String) -> Int {
        clampTemporaryActivityDuration(
            (GeneralSettingsStorage.defaultValues[key] as? Int) ?? temporaryActivityDurationRange.lowerBound
        )
    }
}
