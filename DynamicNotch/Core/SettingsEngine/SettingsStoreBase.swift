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
        (defaults.object(forKey: key) as? NSNumber)?.doubleValue ?? defaultValue
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
        let transform: (@MainActor @Sendable (Value) -> Value)?
        let subject = PassthroughSubject<Value, Never>()

        init(key: String, defaultValue: Value, transform: (@MainActor @Sendable (Value) -> Value)? = nil) {
            self.key = key
            self.defaultValue = defaultValue
            self.transform = transform
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

    init(key: String, defaultValue: Value, transform: (@MainActor @Sendable (Value) -> Value)? = nil) {
        self.storage = Storage(key: key, defaultValue: defaultValue, transform: transform)
    }

    @MainActor
    static subscript<Enclosing: SettingsStoreBase>(
        _enclosingInstance instance: Enclosing,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, StoredDefault<Value>>
    ) -> Value {
        get {
            let storage = instance[keyPath: storageKeyPath].storage
            let rawValue = Value.read(from: instance.defaults, key: storage.key, defaultValue: storage.defaultValue)
            return storage.transform?(rawValue) ?? rawValue
        }
        set {
            (instance.objectWillChange as ObservableObjectPublisher).send()
            let storage = instance[keyPath: storageKeyPath].storage
            let finalValue = storage.transform?(newValue) ?? newValue
            finalValue.write(to: instance.defaults, key: storage.key)
            storage.subject.send(finalValue)
        }
    }

    @MainActor
    static subscript<Enclosing: SettingsStoreBase>(
        _enclosingInstance instance: Enclosing,
        projected projectedKeyPath: KeyPath<Enclosing, AnyPublisher<Value, Never>>,
        storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, StoredDefault<Value>>
    ) -> AnyPublisher<Value, Never> {
        let storage = instance[keyPath: storageKeyPath].storage
        let rawCurrent = Value.read(from: instance.defaults, key: storage.key, defaultValue: storage.defaultValue)
        let current = storage.transform?(rawCurrent) ?? rawCurrent
        return storage.subject
            .prepend(current)
            .eraseToAnyPublisher()
    }
}

@MainActor
class SettingsStoreBase: ObservableObject {
    class var temporaryActivityDurationRange: ClosedRange<Int> { 1...5 }
    class var notificationDurationRange: ClosedRange<Int> { 3...8 }

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

    class func clampNotificationDuration(_ value: Int) -> Int {
        min(
            max(value, notificationDurationRange.lowerBound),
            notificationDurationRange.upperBound
        )
    }

    class func defaultNotificationDuration(for key: String) -> Int {
        clampNotificationDuration(
            (GeneralSettingsStorage.defaultValues[key] as? Int) ?? notificationDurationRange.upperBound
        )
    }
}
