import Foundation
import Combine

protocol StoredSettingValue: Equatable, Sendable {
    static func read(from defaults: UserDefaults, key: String, defaultValue: Self) -> Self
    func write(to defaults: UserDefaults, key: String)
}

extension Bool: StoredSettingValue {
    static func read(from defaults: UserDefaults, key: String, defaultValue: Bool) -> Bool {
        defaults.object(forKey: key) as? Bool ?? defaultValue
    }
    func write(to defaults: UserDefaults, key: String) { defaults.set(self, forKey: key) }
}

extension Int: StoredSettingValue {
    static func read(from defaults: UserDefaults, key: String, defaultValue: Int) -> Int {
        defaults.object(forKey: key) as? Int ?? defaultValue
    }
    func write(to defaults: UserDefaults, key: String) { defaults.set(self, forKey: key) }
}

extension Double: StoredSettingValue {
    static func read(from defaults: UserDefaults, key: String, defaultValue: Double) -> Double {
        defaults.object(forKey: key) as? Double ?? defaultValue
    }
    func write(to defaults: UserDefaults, key: String) { defaults.set(self, forKey: key) }
}

extension String: StoredSettingValue {
    static func read(from defaults: UserDefaults, key: String, defaultValue: String) -> String {
        defaults.string(forKey: key) ?? defaultValue
    }
    func write(to defaults: UserDefaults, key: String) { defaults.set(self, forKey: key) }
}

extension Array: StoredSettingValue where Element == String {
    static func read(from defaults: UserDefaults, key: String, defaultValue: [String]) -> [String] {
        (defaults.object(forKey: key) as? [String]) ?? defaultValue
    }
    func write(to defaults: UserDefaults, key: String) { defaults.set(self, forKey: key) }
}

extension StoredSettingValue where Self: RawRepresentable, Self.RawValue: StoredSettingValue {
    static func read(from defaults: UserDefaults, key: String, defaultValue: Self) -> Self {
        if let raw = defaults.object(forKey: key) as? RawValue, let val = Self(rawValue: raw) {
            return val
        }
        return defaultValue
    }
    func write(to defaults: UserDefaults, key: String) {
        rawValue.write(to: defaults, key: key)
    }
}

@propertyWrapper
struct StoredDefault<Value: StoredSettingValue> {
    final class Storage: @unchecked Sendable {
        let key: String
        let defaultValue: Value
        let subject = PassthroughSubject<Value, Never>()

        init(key: String, defaultValue: Value) {
            self.key = key
            self.defaultValue = defaultValue
        }
    }

    private let storage: Storage

    @available(*, unavailable, message: "@StoredDefault is only available on properties of SettingsStoreBase subclasses")
    var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    @available(*, unavailable, message: "@StoredDefault projectedValue is only available on properties of SettingsStoreBase subclasses")
    var projectedValue: AnyPublisher<Value, Never> {
        get { fatalError() }
    }

    init(key: String, defaultValue: Value) {
        self.storage = Storage(key: key, defaultValue: defaultValue)
    }

    @MainActor
    static subscript<Enclosing: SettingsStoreBase>(
        _enclosingInstance instance: Enclosing,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, StoredDefault<Value>>
    ) -> Value {
        get {
            let storage = instance[keyPath: storageKeyPath].storage
            return Value.read(from: instance.defaults, key: storage.key, defaultValue: storage.defaultValue)
        }
        set {
            (instance.objectWillChange as ObservableObjectPublisher).send()
            let storage = instance[keyPath: storageKeyPath].storage
            newValue.write(to: instance.defaults, key: storage.key)
            storage.subject.send(newValue)
        }
    }

    @MainActor
    static subscript<Enclosing: SettingsStoreBase>(
        _enclosingInstance instance: Enclosing,
        projected projectedKeyPath: KeyPath<Enclosing, AnyPublisher<Value, Never>>,
        storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, StoredDefault<Value>>
    ) -> AnyPublisher<Value, Never> {
        let storage = instance[keyPath: storageKeyPath].storage
        let current = Value.read(from: instance.defaults, key: storage.key, defaultValue: storage.defaultValue)
        return storage.subject
            .prepend(current)
            .eraseToAnyPublisher()
    }
}

@MainActor
class SettingsStoreBase: ObservableObject {
    class var temporaryActivityDurationRange: ClosedRange<Int> { 1...5 }

    let defaults: UserDefaults

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

    func persist(_ value: [String], for key: String) {
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

    func defaultStringArray(for key: String) -> [String] {
        (GeneralSettingsStorage.defaultValues[key] as? [String]) ?? []
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
